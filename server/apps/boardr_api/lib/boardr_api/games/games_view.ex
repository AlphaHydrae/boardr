defmodule BoardrApi.GamesView do
  use BoardrApi, :view

  alias Boardr.Game

  def render("create.json", %{game: game}) do
    render_one(game, __MODULE__, "show.json", as: :game, embed: ["boardr:player"])
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

  def render("show.json", %{game: %Game{} = game} = assigns) do
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

    result = if Ecto.assoc_loaded?(game.winners) and not Enum.empty?(game.winners) do
      result |> Map.put(:_embedded, %{
        'boardr:winners': render_many(game.winners, BoardrApi.Games.PlayersView, "show.json", as: :player)
      })
    else
      result
    end

    embed = Map.get(assigns, :embed, [])
    if Ecto.assoc_loaded?(game.players) and length(game.players) == 1 and "boardr:player" in embed do
      embedded = result[:_embedded] || %{}
      Map.put(result, :_embedded, Map.put(embedded, :'boardr:player', render_one(List.first(game.players), BoardrApi.Games.PlayersView, "show.json", as: :player)))
    else
      result
    end
  end
end
