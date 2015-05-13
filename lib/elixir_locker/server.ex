defmodule Locker.Server do
  
  @doc false
  defmacro __using__(options) do
    lease_length    = Keyword.get(options, :lease_length, 5000)
    lease_threshold = Keyword.get(options, :lease_threshold, 500)
    
    quote location: :keep do
      @lease_length    unquote(lease_length)
      @lease_threshold unquote(lease_threshold)

      use GenServer

      def start(name: name) do
        GenServer.start(__MODULE__, [name: name], name: {:via, __MODULE__, name})
      end
      
      def start_link(name: name) do
        GenServer.start_link(__MODULE__, [name: name], name: {:via, __MODULE__, name})
      end
      
      def whereis_name(name) do
        case :locker.dirty_read(name) do
          {:ok, pid} ->
            pid
          {:error, :not_found} ->
            :undefined
        end
      end
      
      def register_name(name, pid) do
        case :locker.lock(name, pid, @lease_length) do
          {:ok, _, _, _} ->
            Process.send_after(pid,
                               {:'$locker_extend_lease', name, pid},
                               @lease_length - @lease_threshold)            
            :yes
          {:error, :no_quorum} ->
            :no
        end
      end
      
      def unregister_name(name) do
        pid = whereis_name(name)
        if pid != :undefined do
          {:ok, _, _, _} = :locker.release(name, pid)
        end
      end
      
      def send(name, msg) do
        pid = whereis_name(name)
        if pid != :undefined do
          Kernel.send(pid, msg)
        else
          {:badarg, {name, msg}}
        end
      end

      # GenServer API
      
      def init(name: name) do
        Process.put(:'$locker_name', name)
        {:ok, %{}}
      end
      
      def handle_info({:'$locker_extend_lease', key, value}, state) do
        case :locker.extend_lease(key, value, @lease_length) do
          :ok ->
            # schedule new lock lease extend
            Process.send_after(self,
                               {:'$locker_extend_lease', key, value},
                               @lease_length - @lease_threshold)
            {:noreply, state}
          error ->
            {:stop, error, state}
        end
      end

      def terminate(_reason, _state) do
        name = Process.get(:'$locker_name')
        unregister_name(name)
        :ok
      end
      
      defoverridable [init: 1, terminate: 2]
      
      # Internal API
      
      defp lock(name) do
        case :locker.lock(name, self, @lease_length) do
          {:ok, w, nodes, writes} ->
            Process.send_after(self,
                               {:'$locker_extend_lease', name, self},
                               @lease_length - @lease_threshold)
            :ok
          {:error, :no_quorum} ->
            {:error, :no_quorum}
        end
      end
      
    end
  end
  
end
