defmodule BoardrWeb.Games.PossibleActionsView do
  use BoardrWeb, :view

  alias Boardr.Rules.Domain

  require Boardr.Rules.Domain

  def render("index.json", %{embed: embed, game: game, possible_actions: possible_actions}) when is_list(possible_actions) do
    embedded = %{
      'boardr:possible-actions': render_many(possible_actions, __MODULE__, "show.json", as: :possible_action, embed: embed, game: game)
    }
    |> maybe_put("boardr:game" in embed, :'boardr:game', render_one(game, BoardrWeb.GamesView, "show.json", as: :game))

    %{
      _embedded: embedded
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:games_possible_actions_url, [:index, game.id])
  end

  def render("show.json", %{game: game, possible_action: Domain.take(player_number: player_number, position: position)}) do
    player = game.players |> Enum.find(fn player -> player.number === player_number end)

    %{
      position: Domain.position_to_list(position),
      type: "take"
    }
    |> omit_nil()
    |> put_hal_links(%{
      'boardr:game': %{ href: Routes.games_url(Endpoint, :show, game.id) },
      'boardr:player': %{ href: Routes.games_players_url(Endpoint, :show, game.id, player.id) }
    })
  end

  defp maybe_put(map, false, _key, _value) when is_map(map), do: map
  defp maybe_put(map, true, key, value_callback) when is_map(map) and is_function(value_callback, 0), do: Map.put(map, key, value_callback.())
  defp maybe_put(map, true, key, value) when is_map(map), do: Map.put(map, key, value)

  defp put_not_empty(map, key, value) when is_map(map), do: maybe_put(map, !Enum.empty?(value), key, value)

  defp put_not_nil(map, _key, nil) when is_map(map), do: map
  defp put_not_nil(map, key, value) when is_map(map), do: Map.put(map, key, value)
end
