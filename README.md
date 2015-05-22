Locker
======

[![Build Status](https://travis-ci.org/tsharju/elixir_locker.svg?branch=master)](https://travis-ci.org/tsharju/elixir_locker)

A quote from https://github.com/wooga/locker:

> `locker` is a distributed de-centralized consistent in-memory key-value store written in Erlang. An entry expires
> after a certain amount of time, unless the lease is extended. This makes it a good practical option for locks,
> mutexes and leader election in a distributed system.

`Locker`is a Elixir wrapper for the `locker` Erlang library that provides some useful libraries that should make using `locker` a bit easier.

The `Locker` module implements an OTP application that runs `locker`. In addition to that is also provides a wrapper for the `locker` API, just for convenience.

Idea of `Locker` is to provide an abstration for globally registering `GenServer` or `:gen_fsm` processes to `:locker` key-value store in a cluster of Erlang servers. These are implemented in `Locker.Server` and `Locker.Fsm` modules. In the simplest case, all you have to do is replace `use GenServer` with `use Locker.Server` and your process is automatically registered to global `:locker` cluster.

Installing
----------

You can install `Locker` by adding it as a dependency to your project's `mix.exs` file:

```elixir
defp deps do
  [
    {:elixir_locker, "~>v0.1.3"}
  ]
end
```

Also, remember to add `:elixir_locker` to your `:applications` list if you wish that the `Locker` application is started automatically.

Examples
--------

### Globally registered processes

You can use `Locker` as a global process registry. The `Locker.Registry` module handles the API for registering processes in a way that `GenServer` or `:gen_fsm` can use it directly. Here is an example of an `GenServer` process that will be registered to `Locker` on startup:

```elixir
defmodule MyServer do
  use Locker.Server, lease_length: 60000
  
  def init(_) do
    {:ok, %{}}
  end
  
  def handle_info(_info, state) do
    {:noreply, state}
  end
  
end
```

You can start your process with name `"my_server_process"` the way you would start any `GenServer` process. For example, without supervision:

```elixir
iex> MyServer.start([], name: "my_server_process")
{:ok, #PID<0.166.0>}
```

Once the process has been started, you can query the process id using `Locker.Registry` like this:

```elixir
iex> Locker.Registry.whereis_name("my_server_process")
#PID<0.166.0>
```

If `Locker` cluster has been properly configured, you can query the process name from any node on your cluster. What `Locker.Server` does is that it updates the lease on the registered process name within the given `:lease_length`. If the lease expires, the process cannot be found from the registry anymore. Also, `Locker.Server` releases the registered name on `terminate/2`.

### Locking resources

It should not come as a surprise that you can use `Locker` to lock resources globally. For this, you can use `Locker` module that provides a direct mapping to the `:locker` Erlang module. Naturally, you can also use `:locker` directly. Here is how you can create a lock that expires in one minute and wait that the lock gets released.

```elixir
iex(1)> Locker.lock("my_lock", self, 60000)
{:ok, 1, 1, 1}
iex(2)> Locker.wait_for_release("my_lock", 2 * 60000)
{:ok, :released}
```

So what we did here was that we registered a lock called `"my_lock"` and set the value to our own process id and timeout to 60000 milliseconds, i.e. one minute. Then we called `wait_for_release` that will block until the lock is released.
