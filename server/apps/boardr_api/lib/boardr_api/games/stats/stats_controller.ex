defmodule BoardrApi.StatsController do
  use BoardrApi, :controller

  alias Boardr.{Action, Game, Player}
  alias Boardr.Auth.{Identity, User}

  def show(%Conn{} = conn, _params) do
    counts =
      [{:actions, Action}, {:identities, Identity}, {:players, Player}, {:users, User}]
      |> Task.async_stream(__MODULE__, :count_entity, [], on_timeout: :kill_task, ordered: false)
      |> Enum.reduce(%{}, fn result, acc ->
        case result do
          {:ok, {model, count}} -> Map.put(acc, model |> to_string, count)
          _ -> acc
        end
      end)

    game_counts = Repo.all(from(g in Game, group_by: g.state, select: {g.state, count(g.id)}))

    json(conn, %{
      db: Map.merge(counts, count_games()),
      proc: %{
        game_servers: length(Swarm.members(:game_servers))
      }
    })
  end

  def count_entity({name, model}) do
    {
      name,
      Repo.one!(from(e in model, select: count(e.id)))
    }
  end

  defp count_games() do
    inactive_game_threshold_seconds = 30

    inactive_game_threshold =
      DateTime.utc_now() |> DateTime.add(-inactive_game_threshold_seconds, :second)

    count_inactive_games_task =
      Task.async(fn ->
        Repo.one!(
          from(g in Game,
            select: count(g.id),
            where:
              g.state in ["playing", "waiting_for_players"] and
                g.updated_at < ^inactive_game_threshold
          )
        )
      end)

    count_games_task =
      Task.async(fn ->
        Repo.all(from(g in Game, group_by: g.state, select: {g.state, count(g.id)}))
      end)

    game_counts_by_state =
      %{draw: 0, playing: 0, waiting_for_players: 0, win: 0}
      |> Map.merge(
        Task.await(count_games_task)
        |> Enum.reduce(%{}, fn {state, count}, acc -> Map.put(acc, state, count) end)
      )

    %{
      games:
        Map.put(game_counts_by_state, :inactive, %{
          count: Task.await(count_inactive_games_task),
          threshold: inactive_game_threshold_seconds
        })
    }
  end
end
