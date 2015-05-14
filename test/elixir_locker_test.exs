defmodule LockerTest do
  use ExUnit.Case

  alias Locker.Registry
  
  defmodule Server do
    use Locker.Server

    def handle_call(:stop, from, state) do
      GenServer.reply(from, :ok)
      {:stop, :normal, state}
    end
    
    def terminate(reason, state) do
      super(reason, state)
    end
    
  end

  test "start/1 and terminate" do
    {:ok, pid} = Server.start(name: "test")

    assert Registry.whereis_name("test") == pid
    assert GenServer.call({:via, Registry, "test"}, :stop) == :ok

    :timer.sleep(5) # let the process terminate

    # make sure that the name was released
    assert Registry.whereis_name("test") == :undefined
  end

  test "start_link/1 and terminate" do
    {:ok, pid} = Server.start_link(name: "test")
    
    assert Registry.whereis_name("test") == pid
    assert GenServer.call({:via, Registry, "test"}, :stop) == :ok
    
    :timer.sleep(5) # let the process terminate
    
    # make sure that the name was released
    assert Registry.whereis_name("test") == :undefined
  end
  
end
