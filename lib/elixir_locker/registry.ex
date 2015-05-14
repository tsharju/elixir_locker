defmodule Locker.Registry do

  @initial_lease_length    5000
  @initial_lease_threshold 500
  
  def whereis_name(name) do
    case :locker.dirty_read(name) do
      {:ok, pid} ->
        pid
      {:error, :not_found} ->
        :undefined
    end
  end
  
  def register_name(name, pid) do
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
  
  def unregister_name(name) do
    pid = whereis_name(name)
    if pid != :undefined do
      {:ok, _, _, _} = :locker.release(name, pid)
    end
  end
  
  def send(name, msg) do
    pid = whereis_name(name)
    if pid != :undefined do
      Kernel.send(pid, msg)
    else
      {:badarg, {name, msg}}
    end
  end
  
end
