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
  
end
