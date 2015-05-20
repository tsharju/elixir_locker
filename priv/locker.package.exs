defmodule Locker.Erlang.Mixfile do
  use Mix.Project

  def project do
    [app: :locker,
     version: "1.0.6",
     description: description,
     package: package,
     deps: deps]
  end

  defp deps do
    [{:proper, "~> 1.1.0"}]
  end

  defp description do
    """
    Distributed de-centralized consistent in-memory key-value store written in Erlang.
    """
  end

  defp package do
    [files: ~w(src rebar.config README.md LICENSE),
     contributors: ["Knut Nesheim"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/wooga/locker"}]
   end
end
