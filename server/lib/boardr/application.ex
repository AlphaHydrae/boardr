defmodule Boardr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do

    :ok = :telemetry.attach(:boardr, [:boardr, :repo, :query], &Boardr.Telemetry.handle_event/4, %{})

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
      # Start the endpoint when the application starts.
      BoardrWeb.Endpoint,
      # Start the libcluster supervisor.
      {Cluster.Supervisor, [topologies, [name: Boardr.ClusterSupervisor]]},
      # Start a dynamic supervisor to manage gaming servers.
      {DynamicSupervisor, name: Boardr.DynamicSupervisor, strategy: :one_for_one}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Boardr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BoardrWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
