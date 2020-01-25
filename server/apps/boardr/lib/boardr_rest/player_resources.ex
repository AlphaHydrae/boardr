defmodule BoardrRest.PlayerResources do
  use BoardrRest

  alias Boardr.Gaming.GameServer

  @behaviour BoardrRest.Resources

  @impl true
  def handle_operation(operation(type: :create, options: %{game_id: game_id}) = op)
      when is_binary(game_id) do
    with {:ok, {:user, user_id, _}} <- authorize(op, :user, :"api:players:create") do
      GameServer.join(game_id, user_id)
    end
  end
end
