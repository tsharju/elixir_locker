defmodule Locker.Fsm do

  import Locker.Registry
  
  @doc false
  defmacro __using__(options) do
    lease_length    = Keyword.get(options, :lease_length, 5000)
    lease_threshold = Keyword.get(options, :lease_threshold, 500)

    quote location: :keep do
      @lease_length    unquote(lease_length)
      @lease_threshold unquote(lease_threshold)

      @behaviour :gen_fsm

      def start(name: name) do
        :gen_fsm.start({:via, Locker.Registry, name}, __MODULE__, [name: name], [])
      end
      
      def start_link(name: name) do
        :gen_fsm.start_link({:via, Locker.Registry, name}, __MODULE__, [name: name], [])
      end

      # gen_fsm API
      
      def init(name: name) do
        Process.put(:'$locker_name', name)
        {:ok, :init, %{}}
      end

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
        name = Process.get(:'$locker_name')
        unregister_name(name)
        :ok
      end
      
      defoverridable [init: 1, terminate: 3]
      
    end
  end
  
end
