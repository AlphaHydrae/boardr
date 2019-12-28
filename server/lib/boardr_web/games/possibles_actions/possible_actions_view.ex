defmodule BoardrWeb.Games.PossibleActionsView do
  use BoardrWeb, :view

  alias Boardr.{Position,Rules}

  require Boardr.{Position,Rules}

  def render("index.json", %{game: game, possible_actions: possible_actions}) when is_list(possible_actions) do
    %{
      _embedded: %{
        'boardr:possible-actions': render_many(possible_actions, __MODULE__, "show.json", as: :possible_action, game: game)
      }
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:games_possible_actions_url, [:index, game.id])
  end

  def render("show.json", %{game: game, possible_action: Rules.action(type: type, player_number: player_number, position: Position.d2(col: col, row: row))}) do
    player = game.players |> Enum.find(fn player -> player.number === player_number end)
    %{
      position: [col, row],
      type: type
    }
    |> omit_nil()
    |> put_hal_links(%{
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, game.id) },
      'boardr:player': %{ href: Routes.games_players_url(Endpoint, :show, game.id, player.id) }
    })
  end
end
