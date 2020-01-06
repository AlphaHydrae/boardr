defmodule Boardr.MixProject do
  use Mix.Project

  def project do
    [
      app: :boardr,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      elixirc_paths: elixirc_paths(Mix.env()),
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :httpoison,
        :logger,
        :runtime_tools,
        :wx,
        :observer
      ],
      mod: {Boardr.Application, []}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.1"},
      {:httpoison, "~> 1.6"},
      {:inflex, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.0"},
      {:libcluster, "~> 3.1"},
      {:swarm, "~> 3.0"},
      {:postgrex, "~> 0.15.0"},
      # Development
      {:ex_doc, "~> 0.21.2", only: :dev}, # Documentation generator
      # Test
      {:faker, "~> 0.13", only: :test}, # Random data generation
      {:hammox, "~> 0.2.1", only: :test} # Behavior-based mocks
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
