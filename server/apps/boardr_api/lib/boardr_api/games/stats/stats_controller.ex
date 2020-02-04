defmodule BoardrApi.StatsController do
  use BoardrApi, :controller

  alias Boardr.{Action, Game, Player}
  alias Boardr.Auth.{Identity, User}

  def show(%Conn{} = conn, _params) do
    counts = [{:actions, Action}, {:identities, Identity}, {:players, Player}, {:users, User}]
    |> Task.async_stream(__MODULE__, :count_entity, [], on_timeout: :kill_task, ordered: false)
    |> Enum.reduce(%{}, fn result, acc ->
      case result do
        {:ok, {model, count}} -> Map.put(acc, model |> to_string, count)
        _ -> acc
      end
    end)

    game_counts = Repo.all from(g in Game, group_by: g.state, select: {g.state, count(g.id)})

    json(conn, %{
      counts: Map.put(counts, :games, game_counts |> Enum.reduce(%{}, fn {state, count}, acc -> Map.put(acc, state, count) end))
    })
  end

  def count_entity({name, model}) do
    {
      name,
      Repo.one! from(e in model, select: count(e.id))
    }
  end
end
