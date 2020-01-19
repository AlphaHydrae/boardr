defmodule BoardrRes.PossibleActionsCollection do
  use BoardrRes

  alias Boardr.Game
  alias Boardr.Gaming.GameServer

  @behaviour BoardrRes.Collection

  @impl true
  def retrieve(options() = opts) do
    context(options: opts) |> determine_possible_actions()
  end

  defp determine_possible_actions(
         context(options: options(filters: %{game_id: game_id} = filters))
       ) do
    game = Repo.get!(Game, game_id)

    case game.state do
      "playing" ->
        with {:ok, possible_actions} <-
               GameServer.possible_actions(game.id, Map.delete(filters, :game_id)) do
          {:ok, {possible_actions, game}}
        end

      _ ->
        {:ok, {[], game}}
    end
  end
end
