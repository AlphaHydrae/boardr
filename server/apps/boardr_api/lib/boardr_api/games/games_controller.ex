defmodule BoardrApi.GamesController do
  use BoardrApi, :controller

  alias Boardr.Game
  alias BoardrApi.Games.PlayersController
  alias BoardrRes.GamesCollection

  import Boardr.Distributed, only: [distribute: 3]

  require BoardrRes

  def create(
    %Conn{} = conn,
    game_properties
  ) when is_map(game_properties) do
    with {:ok, %Game{} = game} <- distribute(GamesCollection, :create, [game_properties, to_options(conn)]) do
      conn
      |> put_status(201)
      |> put_resp_content_type("application/hal+json")
      |> put_resp_header("location", Routes.games_url(Endpoint, :show, game.id))
      |> render(%{game: game})
    end
  end

  def index(%Conn{} = conn, params) when is_map(params) do
    filters = %{
      state: params["state"]
    }

    filters = if player = conn.query_params["player"] do
      player_urls = if is_list(player), do: player, else: [player]
      player_ids = player_urls
      |> Enum.reduce([], fn player_url, acc ->
        case extract_path_params(player_url, PlayersController) do
          %{"id" => player_id} -> [ player_id | acc ]
          _ -> [ "00000000-0000-0000-0000-000000000000" | acc ]
        end
      end)

      Map.put(filters, :player_ids, player_ids)
    else
      filters
    end

    with {:ok, games} <- distribute(GamesCollection, :retrieve, [to_options(conn, filters: filters)]) do
      conn
      |> put_resp_content_type("application/hal+json")
      |> render(%{games: games})
    end
  end

  def show(%Conn{} = conn, %{"id" => id}) when is_binary(id) do
    game = Repo.get!(Game, id)
    |> Repo.preload([:winners])

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{game: game})
  end
end
