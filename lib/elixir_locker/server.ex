defmodule Locker.Server do

  @moduledoc """
  A utility module that helps in creating `GenServer` processes that
  are registered in `locker.` This module implements functions for
  keeping up the registration. It accepts two parameters, namely
  `:lease_length` and `:lease_threshold`, which defaults to 5 seconds
  and one second. Based on these options, the process registration is
  updated in the progess registry.

  ## Example

  You can create a standard `GenServer` process that is registered
  under `locker` like this:

      defmodule MyServer do
        use Locker.Server, lease_length: 10000

        def init(_) do
          {:ok, %{}}
        end
      end

  Note that `Locker.Server` provides `start/2` and `start_link/2`
  functions that you don't need to implement yourself. If the `opts`
  contains key `name`, this name will be registered under
  `Locker.Registry`.

  Note also that if you need to override `terminate/2` to do some
  cleaning up, you need to remember to add call to `super(reason,
  state)` so that the process will be unregistered on termination.

      defmodule MyServer do
        use Locker.Server

        def init(_) do
          {:ok, %{}}
        end

        def terminate(reason, state) do
          super(reason, state) # will call Locker.Server.terminate/2.
        end
      end
  """
  
  @doc false
  defmacro __using__(options) do
    lease_length    = Keyword.get(options, :lease_length, 5000)
    lease_threshold = Keyword.get(options, :lease_threshold, 500)
    
    quote do
      @lease_length    unquote(lease_length)
      @lease_threshold unquote(lease_threshold)

      use GenServer

      def start(args, opts \\ []) do
        name = Keyword.get(opts, :name)
        if name != nil do
          opts = Keyword.put(opts, :name, {:via, Locker.Registry, name})
          args = Keyword.put(args, :name, name)
        end
        GenServer.start(__MODULE__, args, opts)
      end
        
      def start_link(args, opts \\ []) do
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
