defmodule Locker do

  @moduledoc """
  Provides Elixir API to locker Erlang library as well
  as some utilities that make using locker easier.

  Locker is a distributed, de-centralized, consistent in-memory
  key-value store written in Erlang by a company called Wooga. The
  locker Erlang project can be found from
  `https://github.com/wooga/locker`.

  This module provides pretty much direct mapping of the locker API
  for Elixir as well as some useful mix-in classes for creating long
  running locker registered processes. See `Locker.Server` and
  `Locker.Fsm`. It also provides a process registry,
  `Locker.Registry`, that can be used using e.g., `GenServer`'s
  `{:via, module, term}` API.
  """
  
  use Application

  @type reply :: {:ok, pos_integer, pos_integer, pos_integer}
  
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # locker configuration
    cluster = [Node.self | Node.list]
    primaries = cluster
    replicas = []
    quorum = Application.get_env(:locker, :quorum, 0)
    
    children = [worker(:locker, [quorum])]
    opts = [strategy: :one_for_one, name: Locker.Supervisor]
    
    {:ok, pid} = Supervisor.start_link(children, opts)
    
    # we initialize the locker cluster
    :ok = :locker.set_nodes(cluster, primaries, replicas)

    {:ok, pid}
  end
  
  def stop(_state) do
    :ok
  end

  # the :locker api

  @doc """
  Sets the desired write quorum for the given cluster.
  """
  @spec set_w([atom], pos_integer) :: :ok
  def set_w(cluster, w) do
    :locker.set_w(cluster, w)
  end

  @doc """
  Sets the primaries and replicas for the given
  cluster. Assumes no failures.
  """
  @spec set_nodes([atom], [atom], [atom] | []) :: :ok
  def set_nodes(cluster, primaries, replicas) do
    :locker.set_nodes(cluster, primaries, replicas)
  end

  @doc """
  Tries to acquire the lock.
  """
  @spec lock(any, any, pos_integer, pos_integer) :: reply | {:error, :no_quorum}
  def lock(key, value, lease_length \\ 2000, timeout \\ 5000) do
    :locker.lock(key, value, lease_length, timeout)
  end

  @doc """
  Tries to update the lock. The update only happens if an
  existing value of the lock corresponds to the given `value` within the
  `w` number of master nodes.
  """
  @spec update(any, any, pos_integer, pos_integer) :: reply | {:error, :no_quorum}
  def update(key, value, new_value, timeout \\ 5000) do
    :locker.update(key, value, new_value, timeout)
  end

  @doc """
  Waits for the key to become available on the local node. If a value
  is already available, returns immediately, otherwise it will return
  within the `timeout`. In case of timeout, the caller might get a reply
  anyway if it sent at the same time as the timeout.
  """
  @spec wait_for(any, pos_integer) :: {:ok, any}
  def wait_for(key, timeout \\ 5000) do
    :locker.wait_for(key, timeout)
  end

  @doc """
  Waits for the key to be released.
  """
  @spec wait_for_release(any, pos_integer) :: {:ok, any}
  def wait_for_release(key, timeout \\ 5000) do
    :locker.wait_for_release(key, timeout)
  end

  @doc """
  Releases the lock on given `key`. The `value` needs to match to the
  locked value.
  """
  @spec release(any, any, pos_integer) :: reply | {:error, :no_quorum}
  def release(key, value, timeout \\ 5000) do
    :locker.release(key, value, timeout)
  end

  @doc """
  Extends the lease on given `key` and `value`.
  """
  @spec extend_lease(any, any, pos_integer) :: reply | {:error, :no_quorum}
  def extend_lease(key, value, lease_length \\ 2000) do
    :locker.extend_lease(key, value, lease_length)
  end

  @doc """
  Read the `value` for the given `key`.

  A dirty read does not create a read-quorum so consistency is not
  guaranteed. The value is read directly from a local ETS-table, so
  the performance should be very high.
  """
  @spec dirty_read(any) :: {:ok, any} | {:error, :not_found}
  def dirty_read(key) do
    :locker.dirty_read(key)
  end

  @doc """
  Execute a dirty read on the master. Same caveats as for
  `dirty_read/1`.
  """
  @spec master_dirty_read(any) :: {:ok, any} | {:error, :not_found}
  def master_dirty_read(key) do
    :locker.master_dirty_read(key)
  end

  @doc """
  Provides a lag metric for the cluster.
  """
  @spec lag :: {number, reply}
  def lag do
    :locker.lag()
  end

  @doc """
  Some internal stats.
  """
  @spec summary :: [{:write_locks, pos_integer}, {:leases, pos_integer}]
  def summary do
    :locker.summary()
  end
    
end
