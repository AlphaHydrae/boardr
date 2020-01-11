defmodule Boardr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Boardr.Config

  @epmd_cluster_vars ~w(BOARDR_EPMD_HOSTS)
  @k8s_cluster_vars ~w(BOARDR_K8S_NAMESPACE BOARDR_K8S_NODE_BASENAME BOARDR_K8S_POLLING_INTERVAL BOARDR_K8S_SELECTOR)

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

    {:ok, main_topology} = cluster_topology()

    topologies = [
      main: main_topology
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

  defp cluster_topology() do
    epmd_cluster_explicitly_configured = @epmd_cluster_vars |> Enum.any?(&Config.system_has_env_var/1)
    k8s_cluster_explicitly_configured = @k8s_cluster_vars |> Enum.any?(&Config.system_has_env_var/1)
    cond do
      epmd_cluster_explicitly_configured and k8s_cluster_explicitly_configured ->
        {:error, :multiple_libcluster_topologies_configured}
      k8s_cluster_explicitly_configured ->
        k8s_cluster_topology()
      true ->
        empd_cluster_topology()
    end
  end

  defp empd_cluster_topology() do
    {
      :ok,
      [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: epmd_hosts()
        ]
      ]
    }
  end

  defp epmd_hosts() do
    hosts_string = System.get_env("BOARDR_EPMD_HOSTS")
    case hosts_string do
      nil -> []
      _ -> hosts_string |> String.split(",") |> String.to_atom()
    end
  end

  defp k8s_cluster_topology() do
    {
      :ok,
      [
        strategy: Cluster.Strategy.Kubernetes,
        config: [
          mode: :ip,
          kubernetes_ip_lookup_mode: :pods,
          kubernetes_namespace: System.get_env("BOARDR_K8S_NAMESPACE", "default"),
          kubernetes_node_basename: System.get_env("BOARDR_K8S_NODE_BASENAME", System.get_env("RELEASE_NAME", "boardr")),
          kubernetes_selector: System.get_env("BOARDR_K8S_SELECTOR", "boardr.alphahydrae.io/release=boardr"),
          polling_interval: 5_000
        ]
      ]
    }
  end
end
