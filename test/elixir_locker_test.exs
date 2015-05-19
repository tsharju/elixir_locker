defmodule LockerTest do
  require Logger
  
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
      :ok
    end
    
  end

  defmodule Fsm do
    use Locker.Fsm

    def init(_) do
      {:ok, :started, %{}}
    end
    
    def handle_sync_event(:stop, from, :started, state) do
      :gen_fsm.reply(from, :ok)
      {:stop, :normal, state}
    end

    def terminate(reason, statename, state) do
      Logger.warn "Fsm.terminate/3."
      super(reason, statename, state)
      :ok
    end
    
  end

  test "server start/2 and terminate" do
    {:ok, pid} = Server.start([], [name: "test"])

    assert Registry.whereis_name("test") == pid
    assert GenServer.call({:via, Registry, "test"}, :stop) == :ok

    :timer.sleep(5) # let the process terminate

    # make sure that the name was released
    assert Registry.whereis_name("test") == :undefined
  end

  test "fsm start/2 and terminate" do
    {:ok, pid} = Fsm.start([], [name: "test"])

    assert Registry.whereis_name("test") == pid
    assert :gen_fsm.sync_send_all_state_event({:via, Registry, "test"}, :stop) == :ok

    :timer.sleep(5) # let the process terminate

    # make sure that the name was released
    assert Registry.whereis_name("test") == :undefined
  end

  test "server start_link/2 and terminate" do
    {:ok, pid} = Server.start_link([], [name: "test"])
    
    assert Registry.whereis_name("test") == pid
    assert GenServer.call({:via, Registry, "test"}, :stop) == :ok
    
    :timer.sleep(5) # let the process terminate
    
    # make sure that the name was released
    assert Registry.whereis_name("test") == :undefined
  end

  test "fsm start_link/2 and terminate" do
    {:ok, pid} = Fsm.start_link([], [name: "test"])
    
    assert Registry.whereis_name("test") == pid
    assert :gen_fsm.sync_send_all_state_event({:via, Registry, "test"}, :stop) == :ok
    
    :timer.sleep(5) # let the process terminate
    
    # make sure that the name was released
    assert Registry.whereis_name("test") == :undefined
  end
  
  test "server start/2 without opts" do
    {:ok, pid} = Server.start([])
    
    assert is_pid(pid)
  end

  test "fsm start/2 without opts" do
    {:ok, pid} = Fsm.start([])
    
    assert is_pid(pid)
  end

  test "server start_link/2 without opts" do
    {:ok, pid} = Server.start_link([])
    
    assert is_pid(pid)
  end
  
  test "fsm start_link/2 without opts" do
    {:ok, pid} = Fsm.start_link([])
    
    assert is_pid(pid)
  end
  
end
