defmodule BoardrRest.PlayersService do
  use BoardrRest

  alias Boardr.Game
  alias Boardr.Gaming.LobbyServer

  @behaviour BoardrRest.Service

  @impl true
  def handle_operation(operation(type: :create) = op) do
    op |> authorize(:"api:players:create") >>> join_game()
  end

  def join_game(
        operation(options: %{authorization_claims: %{"sub" => user_id}, game_id: game_id})
      )
      when is_binary(user_id) and is_binary(game_id) do
    game_state = Repo.one!(from(g in Game, select: g.state, where: g.id == ^game_id))
    join_game(game_id, game_state, user_id)
  end

  defp join_game(game_id, "waiting_for_players", user_id)
       when is_binary(game_id) and is_binary(user_id) do
    LobbyServer.join(game_id, user_id)
  end

  defp join_game(game_id, game_state, user_id)
       when is_binary(game_id) and is_binary(game_state) and is_binary(user_id) do
    {:error, {:game_error, :game_already_started}}
  end
end
