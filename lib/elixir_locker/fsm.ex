defmodule Locker.Fsm do
  
  @doc false
  defmacro __using__(options) do
    lease_length    = Keyword.get(options, :lease_length, 5000)
    lease_threshold = Keyword.get(options, :lease_threshold, 500)

    quote location: :keep do
      @lease_length    unquote(lease_length)
      @lease_threshold unquote(lease_threshold)

      @behaviour :gen_fsm

      def start(args, opts \\ []) do
        name = Keyword.get(opts, :name)
        if name != nil do
          opts = Keyword.delete(opts, :name)
        end
        :gen_fsm.start({:via, Locker.Registry, name}, __MODULE__, args, opts)
      end
      
      def start_link(args, opts \\ []) do
        name = Keyword.get(args, :name)
        if name != nil do
          opts = Keyword.delete(opts, :name)
        end
        :gen_fsm.start_link({:via, Locker.Registry, name}, __MODULE__, args, opts)
      end

      # gen_fsm API
      
      def handle_info({:'$locker_extend_lease', key, value}, statename, state) do
        case :locker.extend_lease(key, value, @lease_length) do
          :ok ->
            # schedule new lock lease extend
            Process.send_after(self,
                               {:'$locker_extend_lease', key, value},
                               @lease_length - @lease_threshold)
            {:next_state, statename, state}
          error ->
            {:stop, error, state}
        end
      end

      def terminate(_reason, _statename, _state) do
        Locker.registry.unregister
        :ok
      end
      
      defoverridable [terminate: 3]
      
    end
  end
  
end
