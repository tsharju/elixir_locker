defmodule Locker do

  use Application

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

  def set_w(cluster, w) do
    :locker.set_w(cluster, w)
  end

  def set_nodes(cluster, primaries, replicas) do
    :locker.set_nodes(cluster, primaries, replicas)
  end

  def lock(key, value, lease_length \\ 2000, timeout \\ 5000) do
    :locker.lock(key, value, lease_length, timeout)
  end

  def update(key, value, new_value, timeout \\ 5000) do
    :locker.update(key, value, new_value, timeout)
  end

  def wait_for(key, timeout \\ 5000) do
    :locker.wait_for(key, timeout)
  end

  def wait_for_release(key, timeout \\ 5000) do
    :locker.wait_for_release(key, timeout)
  end

  def release(key, value, timeout \\ 5000) do
    :locker.release(key, value, timeout)
  end

  def extend_lease(key, value, lease_length \\ 2000) do
    :locker.extend_lease(key, value, lease_length)
  end

  def dirty_read(key) do
    :locker.dirty_read(key)
  end

  def master_dirty_read(key) do
    :locker.master_dirty_read(key)
  end

  def lag do
    :locker.lag()
  end

  def summary do
    :locker.summary()
  end
    
end
