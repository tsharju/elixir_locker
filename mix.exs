defmodule Locker.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_locker,
     version: "0.1.4-dev",
     description: "Elixir wrapper for the locker Erlang library.",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     name: "Locker",
     source_url: "https://github.com/tsharju/elixir_locker",
     homepage_url: "https://github.com/tsharju/elixir_locker",
     docs: docs,
     deps: deps,
     package: package]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :locker],
     mod: {Locker, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
        {:earmark, "~> 0.1", only: :dev},
        {:ex_doc, "~> 0.7", only: :dev},
        {:locker, "~> 1.0.6"}
    ]
  end

  defp docs do
    [
        readme: "README.md"
    ]
  end

  defp package do
    [
        files: ~w(lib mix.exs README.md LICENSE),
        contributors: ["Teemu Harju"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/tsharju/elixir_locker"}
    ]
  end
end
