defmodule Locker.Server do
  
  @doc false
  defmacro __using__(options) do
    lease_length    = Keyword.get(options, :lease_length, 5000)
    lease_threshold = Keyword.get(options, :lease_threshold, 500)
    
    quote do
      @lease_length    unquote(lease_length)
      @lease_threshold unquote(lease_threshold)

      use GenServer

      def start(args, opts) do
        name = Keyword.get(opts, :name)
        if name != nil do
          opts = Keyword.put(opts, :name, {:via, Locker.Registry, name})
          args = Keyword.put(args, :name, name)
        end
        GenServer.start(__MODULE__, args, opts)
      end
        
      def start_link(args, opts) do
        name = Keyword.get(opts, :name)
        if name != nil do
          opts = Keyword.put(opts, :name, {:via, Locker.Registry, name})
          args = Keyword.put(args, :name, name)
        end
        GenServer.start_link(__MODULE__, args, opts)
      end
      
      # GenServer API
      
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
        Locker.Registry.unregister
        :ok
      end
      
      defoverridable [terminate: 2]
      
    end
  end
  
end
