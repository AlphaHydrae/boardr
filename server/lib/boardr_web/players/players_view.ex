defmodule BoardrWeb.PlayersView do
  use BoardrWeb, :view

  alias Boardr.Player

  def render("create.json", %{player: %Player{} = player}) do
    render_one player, __MODULE__, "show.json", as: :player
  end

  def render("show.json", %{player: %Player{} = player}) do
    %{
      createdAt: player.created_at,
      number: player.number
    }
    |> put_hal_curies_link()
    |> put_hal_links(%{
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, player.game_id) },
      'boardr:user': %{ href: Routes.users_url(Endpoint, :show, player.user_id) }
    })
    |> put_hal_self_link(:games_players_url, [:show, player.game_id, player.id])
  end
end
