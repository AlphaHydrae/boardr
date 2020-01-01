defmodule BoardrWeb.Games.ActionsView do
  use BoardrWeb, :view

  alias Boardr.Action

  def render("create.json", %{action: %Action{} = action}) do
    render_one action, __MODULE__, "show.json", as: :action
  end

  def render("index.json", %{actions: actions, game_id: game_id}) when is_list(actions) do
    %{
      _embedded: %{
        'boardr:actions': render_many(actions, __MODULE__, "show.json", as: :action)
      }
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:games_actions_url, [:index, game_id])
  end

  def render("show.json", %{action: %Action{} = action}) do
    %{
      performedAt: action.performed_at,
      position: action.position,
      type: action.type
    }
    |> omit_nil()
    |> put_hal_curies_link()
    |> put_hal_links(%{
      collection: %{ href: Routes.games_actions_url(Endpoint, :index, action.game_id) },
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, action.game_id) },
      'boardr:player': %{ href: Routes.games_players_url(Endpoint, :show, action.game_id, action.player_id) }
    })
    |> put_hal_self_link(:games_actions_url, [:show, action.game_id, action.id])
  end
end
