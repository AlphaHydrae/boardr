defmodule BoardrRest.ActionsService do
  use BoardrRest

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
    GameServer.play(game_id, user_id, entity)
  end
end
