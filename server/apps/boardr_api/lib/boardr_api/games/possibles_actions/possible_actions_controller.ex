defmodule BoardrApi.Games.PossibleActionsController do
  use BoardrApi, :controller

  alias Boardr.{Game, Repo}
  alias Boardr.Gaming.GameServer
  alias BoardrApi.Games.PlayersController

  def index(%Conn{} = conn, %{"game_id" => game_id}) do

    game = Repo.one!(from(g in Game, left_join: p in assoc(g, :players), preload: [players: p], where: g.id == ^game_id))

    filters = if player = conn.query_params["player"] do
      player_urls = if is_list(player), do: player, else: [player]
      player_ids = player_urls
      |> Enum.reduce([], fn player_url, acc ->
        case extract_path_params(player_url, PlayersController) do
          %{"game_id" => ^game_id, "id" => player_id} -> [ player_id | acc ]
          _ -> acc
        end
      end)

      # TODO: validate players exist
      %{
        player_ids: player_ids
      }
    else
      %{}
    end

    {:ok, possible_actions} = case game.state do
      "playing" -> GameServer.possible_actions(game.id, filters)
      _ -> {:ok, []}
    end

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{
      embed: to_list(conn.query_params["embed"]),
      game: game,
      possible_actions: possible_actions
    })
  end

  # TODO: extract to utility module
  defp extract_path_params(url, plug) do
    # TODO: check host, path, port & scheme match
    %URI{host: host, path: path} = URI.parse(url)
    # FIXME: host & path can be nil
    case Phoenix.Router.route_info(Router, "GET", path, host) do
      %{path_params: path_params, plug: ^plug, plug_opts: :show} -> path_params
      _ -> nil
    end
  end

  # TODO: extract to utility module
  defp to_list(value, default \\ [])

  defp to_list(value, default) when is_list(value) and is_list(default) do
    value
  end

  defp to_list(value, default) when is_list(default) do
    if value, do: [value], else: default
  end
end
