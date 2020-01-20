defmodule BoardrRest.PlayersService do
  use BoardrRest

  alias Boardr.Gaming.GameServer

  @behaviour BoardrRest.Service

  @impl true
  def handle_operation(operation(type: :create) = op) do
    op |> authorize(:"api:players:create") >>> join_game()
  end

  def join_game(
        operation(options: %{authorization_claims: %{"sub" => user_id}, game_id: game_id})
      )
      when is_binary(user_id) and is_binary(game_id) do
    GameServer.join(game_id, user_id)
  end
end
