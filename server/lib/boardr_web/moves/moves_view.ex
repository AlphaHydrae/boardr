defmodule BoardrWeb.MovesView do
  use BoardrWeb, :view
  alias Boardr.Move

  def render("create.json", %{move: %Move{} = move}) do
    render_one move, __MODULE__, "show.json", as: :move
  end

  def render("index.json", %{game_id: game_id, moves: moves}) when is_list(moves) do
    %{
      _embedded: %{
        'boardr:moves': render_many(moves, __MODULE__, "show.json", as: :move)
      }
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:games_moves_url, [:index, game_id])
  end

  def render("show.json", %{move: %Move{} = move}) do
    %{
      data: move.data,
      playedAt: move.played_at,
      type: move.type
    }
    |> omit_nil()
    |> put_hal_curies_link()
    |> put_hal_links(%{
      collection: %{ href: Routes.games_moves_url(Endpoint, :index, move.game_id) },
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, move.game_id) },
      'boardr:player': %{ href: Routes.games_players_url(Endpoint, :show, move.game_id, move.player_id) }
    })
    |> put_hal_self_link(:games_moves_url, [:show, move.game_id, move.id])
  end
end
