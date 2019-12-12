defmodule BoardrWeb.GamesView do
  use BoardrWeb, :view

  def render("create.json", %{game: game}) do
    render_game game
  end

  def render("index.json", %{games: games}) do
    %{
      _embedded: %{
        'boardr:games': render_many(games, __MODULE__, "show.json", as: :game)
      }
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:games_url, [:index])
  end

  def render("show.json", %{game: game}) do
    render_game game
  end

  defp render_game(game) do
    %{
      createdAt: game.created_at,
      settings: game.settings,
      title: game.title,
      updatedAt: game.updated_at
    }
    |> omit_nil()
    |> put_hal_links(%{
      'boardr:board': %{ href: Routes.games_board_url(Endpoint, :show, game.id) },
      'boardr:creator': %{ href: Routes.users_url(Endpoint, :show, game.creator_id) },
      'boardr:players': %{ href: Routes.games_players_url(Endpoint, :create, game.id) },
      collection: %{ href: Routes.games_url(Endpoint, :index) }
    })
    |> put_hal_self_link(:games_url, [:show, game.id])
  end
end
