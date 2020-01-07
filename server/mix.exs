defmodule Boardr.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end

  defp releases() do
    [
      boardr: [
        include_executables_for: [:unix],
        applications: [
          boardr: :permanent,
          runtime_tools: :permanent
        ]
      ],
      boardr_api: [
        include_executables_for: [:unix],
        applications: [
          boardr_api: :permanent,
          runtime_tools: :permanent
        ]
      ]
    ]
  end
end
