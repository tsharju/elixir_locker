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
        GenServer.start(__MODULE__, [name: name], name: {:via, Locker.Registry, name})
      end
      
      def start_link(name: name) do
        GenServer.start_link(__MODULE__, [name: name], name: {:via, Locker.Registry, name})
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
      
    end
  end
  
end
