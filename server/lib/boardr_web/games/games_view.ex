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
    result = %{
      createdAt: game.created_at,
      rules: game.rules,
      settings: game.settings,
      state: game.state,
      title: game.title,
      updatedAt: game.updated_at
    }
    |> omit_nil()
    |> put_hal_curies_link()
    |> put_hal_links(%{
      'boardr:actions': %{ href: Routes.games_actions_url(Endpoint, :index, game.id) },
      'boardr:board': %{ href: Routes.games_board_url(Endpoint, :show, game.id) },
      'boardr:creator': %{ href: Routes.users_url(Endpoint, :show, game.creator_id) },
      'boardr:players': %{ href: Routes.games_players_url(Endpoint, :create, game.id) },
      'boardr:possible-actions': %{ href: Routes.games_possible_actions_url(Endpoint, :index, game.id) },
      collection: %{ href: Routes.games_url(Endpoint, :index) }
    })
    |> put_hal_self_link(:games_url, [:show, game.id])

    if Ecto.assoc_loaded?(game.winners) and not Enum.empty?(game.winners) do
      result |> Map.put(:_embedded, %{
        'boardr:winners': render_many(game.winners, BoardrWeb.Games.PlayersView, "show.json", as: :player)
      })
    else
      result
    end
  end
end
