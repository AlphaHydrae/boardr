defmodule BoardrRest.ActionResources do
  use BoardrRest

  alias Boardr.Gaming.GameServer

  @behaviour BoardrRest.Resources

  @impl true
  def handle_operation(
        operation(type: :create, data: http_request(body: body), options: %{game_id: game_id}) = op
      )
      when is_binary(game_id) do
    with {:ok, {:user, user_id, _}} <- authorize(op, :user, :"api:actions:create"),
         {:ok, action_properties} <- parse_json_object(body) do
      GameServer.play(game_id, user_id, action_properties)
    end
  end
end
