defmodule Boardr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Boardr.Config

  require Logger

  @epmd_cluster_vars ~w(BOARDR_EPMD_HOSTS)
  @k8s_cluster_vars ~w(BOARDR_K8S_NAMESPACE BOARDR_K8S_NODE_BASENAME BOARDR_K8S_POLLING_INTERVAL BOARDR_K8S_SELECTOR)
  @log_levels ~w(debug info warn error)

  def start(_type, _args) do
    compiled_env =
      case Application.fetch_env(:boardr, Boardr.Auth) do
        {:ok, env} -> env
        _ -> []
      end

    {:ok, secret_key_base} =
      Config.get_required_env(
        "BOARDR_SECRET",
        :secret_missing,
        Keyword.get(compiled_env, :secret_key_base)
      )

    env = compiled_env
    |> Keyword.put(:secret_key_base, secret_key_base)

    if env != compiled_env,
      do: Application.put_env(:boardr, Boardr.Auth, env)

    if node_whitelist_string = System.get_env("BOARDR_SWARM_NODE_WHITELIST") do
      Application.put_env(:swarm, :node_whitelist, String.split(node_whitelist_string, ","))
      Logger.info("Configured swarm node whitelist to #{node_whitelist_string}")
    end

    if node_blacklist_string = System.get_env("BOARDR_SWARM_NODE_BLACKLIST") do
      Application.put_env(:swarm, :node_blacklist, String.split(node_blacklist_string, ","))
      Logger.info("Configured swarm node blacklist to #{node_blacklist_string}")
    end

    :ok =
      :telemetry.attach(:boardr, [:boardr, :repo, :query], &Boardr.Telemetry.handle_event/4, %{})

    {:ok, log_level} = get_log_level()
    if Logger.level() != log_level do
      Logger.configure(level: log_level)
    end

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
      {DynamicSupervisor, name: Boardr.DynamicSupervisor, strategy: :one_for_one},
      # Start a task supervisor to manage asynchronous tasks.
      {Task.Supervisor, name: Boardr.TaskSupervisor},
      # Start a server that will keep track of what happens in the application.
      Boardr.StatsServer
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
      _ -> hosts_string |> String.split(",") |> Enum.map(&String.to_atom/1)
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

  defp get_log_level() do
    log_level_string = "BOARDR_LOG_LEVEL" |> System.get_env()
    case log_level_string do
      nil ->
        {
          :ok,
          Application.fetch_env!(:logger, :console) |> Keyword.fetch!(:level)
        }
      _ ->
        normalized_log_level_string = String.downcase(log_level_string)
        if normalized_log_level_string in @log_levels do
          {
            :ok,
            String.to_atom(normalized_log_level_string)
          }
        else
          {
            :error,
            {:unsupported_log_level, log_level_string}
          }
        end
    end
  end
end
