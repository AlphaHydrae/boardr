defmodule Boardr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Boardr.Config

  def start(_type, _args) do
    compiled_env =
      case Application.fetch_env(:boardr, Boardr.Auth.Token) do
        {:ok, env} -> env
        _ -> nil
      end

    {:ok, private_key} =
      Config.get_required_env(
        "BOARDR_PRIVATE_KEY",
        :private_key_missing,
        Keyword.get(compiled_env, :private_key)
      )

    env = compiled_env
    |> Keyword.put(:private_key, private_key)

    if env != compiled_env,
      do: Application.put_env(:boardr, Boardr.Auth.Token, env)

    :ok =
      :telemetry.attach(:boardr, [:boardr, :repo, :query], &Boardr.Telemetry.handle_event/4, %{})

    topologies = [
      main: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: []]
      ]
    ]

    # List all child processes to be supervised
    children = [
      # Start the Ecto repository.
      Boardr.Repo,
      # Start the libcluster supervisor.
      {Cluster.Supervisor, [topologies, [name: Boardr.ClusterSupervisor]]},
      # Start a dynamic supervisor to manage gaming servers.
      {DynamicSupervisor, name: Boardr.DynamicSupervisor, strategy: :one_for_one}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    Supervisor.start_link(children, strategy: :one_for_one, name: Boardr.Supervisor)
  end
end
