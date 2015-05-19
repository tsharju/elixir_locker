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
          :gen_fsm.start({:via, Locker.Registry, name}, __MODULE__, args, opts)
        else
          :gen_fsm.start(__MODULE__, args, opts)
        end
      end
      
      def start_link(args, opts \\ []) do
        name = Keyword.get(opts, :name)
        if name != nil do
          opts = Keyword.delete(opts, :name)
          :gen_fsm.start_link({:via, Locker.Registry, name}, __MODULE__, args, opts)
        else
          :gen_fsm.start_link(__MODULE__, args, opts)
        end
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
      
      def handle_event(_event, _statename, state) do
        {:stop, :not_implemented, state}
      end
      
      def handle_sync_event(_event, _from, statename, state) do
        {:stop, :not_implemented, {:error, :not_implemented}, state}
      end
      
      def code_change(_oldvsn, statename, state, _extra) do
        {:ok, statename, state}
      end
      
      def terminate(_reason, _statename, _state) do
        Locker.Registry.unregister
        :ok
      end
      
      defoverridable [handle_event: 3, handle_sync_event: 4,
                      code_change: 4, terminate: 3]
      
    end
  end
  
end
