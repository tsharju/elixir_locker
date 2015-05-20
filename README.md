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
