defmodule BoardrApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :boardr_api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :runtime_tools,
        :wx,
        :observer
      ],
      mod: {BoardrApi.Application, []}
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:boardr, in_umbrella: true},
      {:content_type, "~> 0.1.0"},
      {:corsica, "~> 1.0"},
      {:inflex, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.4.11"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:plug_cowboy, "~> 2.0"},
      # Development
      {:ex_doc, "~> 0.21.2", only: :dev}, # Documentation generator
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
