defmodule BoardrWeb.Games.PossibleMovesView do
  use BoardrWeb, :view

  alias Boardr.PossibleMove

  def render("index.json", %{game_id: game_id, possible_moves: possible_moves}) when is_list(possible_moves) do
    %{
      _embedded: %{
        'boardr:possible-moves': render_many(possible_moves, __MODULE__, "show.json", as: :possible_move, game_id: game_id)
      }
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:games_possible_moves_url, [:index, game_id])
  end

  def render("show.json", %{game_id: game_id, possible_move: %PossibleMove{} = possible_move}) do
    %{
      data: possible_move.data,
      type: possible_move.type
    }
    |> omit_nil()
    |> put_hal_links(%{
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, game_id) },
      'boardr:player': %{ href: Routes.games_players_url(Endpoint, :show, game_id, possible_move.player.id) }
    })
  end
end
