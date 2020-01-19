defmodule BoardrRest.ActionsService do
  use BoardrRest

  alias Boardr.Player
  alias Boardr.Gaming.GameServer

  @behaviour BoardrRest.Service

  @impl true
  def handle_operation(operation(type: :create) = op) do
    op
    |> authorize(:"api:actions:create") >>>
      parse_json_object_entity() >>>
      play()
  end

  def play(
        operation(
          options: %{
            authorization_claims: %{"sub" => user_id},
            game_id: game_id,
            parsed_entity: entity
          }
        )
      )
      when is_binary(user_id) and is_binary(game_id) and is_map(entity) do
    {player_id, game_state} =
      Repo.one!(
        from(p in Player,
          join: g in assoc(p, :game),
          select: {p.id, g.state},
          where: p.game_id == ^game_id and p.user_id == ^user_id
        )
      )

    play(game_id, game_state, player_id, entity)
  end

  defp play(game_id, "waiting_for_players", player_id, action_properties)
       when is_binary(game_id) and is_binary(player_id) and is_map(action_properties) do
    {:error, {:game_error, :game_not_started}}
  end

  defp play(game_id, "playing", player_id, action_properties)
       when is_binary(game_id) and is_binary(player_id) and is_map(action_properties) do
    GameServer.play(game_id, player_id, action_properties)
  end

  defp play(game_id, game_state, player_id, action_properties)
       when is_binary(game_id) and is_binary(game_state) and is_binary(player_id) and
              is_map(action_properties) do
    {:error, {:game_error, :game_finished}}
  end
end
