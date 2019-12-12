defmodule BoardrWeb.Games.PossibleActionsView do
  use BoardrWeb, :view

  alias Boardr.{Position,PossibleAction}

  def render("index.json", %{game_id: game_id, possible_actions: possible_actions}) when is_list(possible_actions) do
    %{
      _embedded: %{
        'boardr:possible-actions': render_many(possible_actions, __MODULE__, "show.json", as: :possible_action, game_id: game_id)
      }
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:games_possible_actions_url, [:index, game_id])
  end

  def render("show.json", %{game_id: game_id, possible_action: %PossibleAction{} = possible_action}) do
    %{
      position: possible_action.position |> Position.parse() |> Tuple.delete_at(0) |> Tuple.to_list(),
      type: possible_action.type
    }
    |> omit_nil()
    |> put_hal_links(%{
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, game_id) },
      'boardr:player': %{ href: Routes.games_players_url(Endpoint, :show, game_id, possible_action.player.id) }
    })
  end
end
