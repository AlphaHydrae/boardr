defmodule BoardrApi.Games.PossibleActionsController do
  use BoardrApi, :controller

  alias Boardr.Game
  alias BoardrApi.Games.PlayersController
  alias BoardrRes.PossibleActionsCollection

  import Boardr.Data, only: [to_list: 1]
  import Boardr.Distributed, only: [distribute: 3]

  def index(%Conn{} = conn, %{"game_id" => game_id}) do

    filters = %{game_id: game_id}

    filters = if player = conn.query_params["player"] do
      player_ids = to_list(player)
      |> Enum.reduce([], fn player_url, acc ->
        case extract_path_params(player_url, PlayersController) do
          %{"game_id" => ^game_id, "id" => player_id} -> [ player_id | acc ]
          _ -> [ "" | acc ]
        end
      end)

      Map.put(filters, :player_ids, player_ids)
    else
      filters
    end

    with {:ok, {possible_actions, %Game{} = game}} <- distribute(PossibleActionsCollection, :retrieve, [to_options(conn, filters: filters)]) do
      conn
      |> put_resp_content_type("application/hal+json")
      |> render(%{
        embed: to_list(conn.query_params["embed"]),
        game: game,
        possible_actions: possible_actions
      })
    end
  end
end
