defmodule BoardrWeb.Games.PossibleActionsController do
  use BoardrWeb, :controller

  alias Boardr.{Game, Repo}
  alias Boardr.Gaming.GameServer

  def index(%Conn{} = conn, %{"game_id" => game_id}) do

    game = Repo.get!(Game, game_id)
    |> Repo.preload([:players])

    filters = if player = conn.query_params["player"] do
      # TODO: find out if Phoenix router can do this?
      player_url_regex = Routes.games_players_url(Endpoint, :show, game_id, "00000000-0000-0000-0000-000000000000")
      |> String.split("00000000-0000-0000-0000-000000000000")
      |> Enum.with_index()
      |> Enum.map(fn {part, i} ->
        if part == "" do
          "(?<m#{i}>[\\w-]+)"
        else
          Regex.escape(part)
        end
      end)
      |> Enum.join()
      |> (&("\\A#{&1}\\z")).()
      |> Regex.compile!()

      player_urls = if is_list(player), do: player, else: [player]
      player_ids = player_urls
      |> Enum.map(fn player_url -> Regex.named_captures(player_url_regex, player_url) end)
      |> Enum.filter(&(&1))
      |> Enum.map(fn captures -> captures["m1"] end)

      %{
        player_ids: player_ids
      }
    else
      %{}
    end

    {:ok, possible_actions} = if game.state == "waiting_for_players" do
      {:ok, []}
    else
      GameServer.possible_actions(game.id, filters)
    end

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{
      embed: to_list(conn.query_params["embed"]),
      game: game,
      possible_actions: possible_actions
    })
  end

  defp to_list(value, default \\ [])

  defp to_list(value, default) when is_list(value) and is_list(default) do
    value
  end

  defp to_list(value, default) when is_list(default) do
    if value, do: [value], else: default
  end
end
