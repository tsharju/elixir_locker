defmodule Locker.Registry do

  @moduledoc """
  This module provides a global process registry using `locker` Erlang
  library as the storage backend. It supports e.g., the `GenServer`'s
  `{:via, module, term}` API.

  ## Example

  You can spawn a regular `GenServer` process that will be registered
  to `locker` using the GenServer API directly.

      GenServer.start([], [name: {:via, Locker.Registry, "my_process"}])

  Note that when using `GenServer`, you will need to refresh the registration
  using `Locker.extend_lease/3`. To avoid this, you should use
  `Locker.Server` instead of `GenServer` directly.

  You can find out the process id of the named process using
  `Locker.Registry.whereis_name`.

      Locker.Registry.whereis_name("my_process")
      #=> {:ok, pid}

  You can uregister the named process by calling
  `Locker.Registry.unregister`.

      Locker.Registry.unregister("my_process")
  """
  
  @initial_lease_length    5000
  @initial_lease_threshold 500

  @doc """
  Finds the process identifier for the given `name`.
  """
  @spec whereis_name(any) :: pid | :undefined
  def whereis_name(name) do
    case :locker.dirty_read(name) do
      {:ok, pid} ->
        pid
      {:error, :not_found} ->
        :undefined
      {:error, :no_quorum} ->
        :undefined
    end
  end

  @doc """
  Registers the given `pid` to a `name` globally.
  """
  @spec register_name(any, pid) :: :yes | :no
  def register_name(name, pid) do
    if pid == self do
      Process.put(:'$locker_name', name)
    end
    
    case :locker.lock(name, pid, @initial_lease_length) do
      {:ok, _, _, _} ->
        Process.send_after(pid,
                           {:'$locker_extend_lease', name, pid},
                           @initial_lease_length - @initial_lease_threshold)
        :yes
      {:error, :no_quorum} ->
        :no
    end
  end

  @doc """
  Unregisters the given `name`.
  """
  @spec unregister_name(any) :: nil
  def unregister_name(name) do
    pid = whereis_name(name)
    if pid != :undefined do
      {:ok, _, _, _} = :locker.release(name, pid)
    end
  end

  @doc """
  Unregisters the calling process.
  """
  @spec unregister :: nil
  def unregister do
    name = Process.get(:'$locker_name')
    unregister_name(name)
  end

  @doc """
  Sends a message to the given `name`.
  """
  @spec send(any, any) :: :ok | {:badarg, {any, any}}
  def send(name, msg) do
    pid = whereis_name(name)
    if pid != :undefined do
      Kernel.send(pid, msg)
    else
      {:badarg, {name, msg}}
    end
  end
  
end
