defmodule BoardrWeb.UsersController do
  use BoardrWeb, :controller

  alias Boardr.Auth

  plug Authenticate, [:register] when action in [:create]

  def create(%Conn{} = conn, body) do
    with {:ok, user} <- Auth.register_user(body) do
      conn
      |> put_status(:created)
      |> render(%{user: user})
    end
  end
end
