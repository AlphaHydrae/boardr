defmodule BoardrApi.Games.PossibleActionsController do
  use BoardrApi, :controller

  alias Boardr.Game
  alias BoardrRest.PossibleActionsService

  def index(%Conn{} = conn, %{"game_id" => game_id}) do
    with {:ok, {possible_actions, %Game{} = game, embed}} <-
           distribute_to_service(conn, PossibleActionsService, :retrieve, %{id: game_id}) do
      conn
      |> put_resp_content_type("application/hal+json")
      |> render(%{
        embed: embed,
        game: game,
        possible_actions: possible_actions
      })
    end
  end
end
