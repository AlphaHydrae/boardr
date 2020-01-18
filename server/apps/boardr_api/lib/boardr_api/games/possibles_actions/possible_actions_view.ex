defmodule BoardrApi.Games.PossibleActionsView do
  use BoardrApi, :view

  alias Boardr.{Action, Game}

  def render("index.json", %{embed: embed, game: %Game{id: game_id} = game, possible_actions: possible_actions}) when is_list(embed) and is_binary(game_id) and is_list(possible_actions) do
    embedded = %{
      'boardr:possible-actions': render_many(possible_actions, __MODULE__, "show.json", as: :possible_action, embed: embed)
    }
    |> maybe_put("boardr:game" in embed, :'boardr:game', render_one(game, BoardrApi.GamesView, "show.json", as: :game))

    %{
      _embedded: embedded
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:games_possible_actions_url, [:index, game_id])
  end

  def render("show.json", %{possible_action: %Action{game_id: game_id, player_id: player_id, position: position}}) do
    %{
      position: position,
      type: "take"
    }
    |> omit_nil()
    |> put_hal_links(%{
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, game_id) },
      'boardr:player': %{ href: Routes.games_players_url(Endpoint, :show, game_id, player_id) }
    })
  end
end
