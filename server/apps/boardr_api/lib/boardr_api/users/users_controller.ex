defmodule BoardrApi.UsersController do
  use BoardrApi, :controller

  alias Boardr.Auth.User
  alias BoardrRest.UserResources

  def create(%Conn{} = conn, body) when is_map(body) do
    # FIXME: only allow local identity with unverified email in dev
    with {:ok, %User{} = user} <- rest(conn, UserResources, :create) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.users_url(Endpoint, :show, user.id))
      |> render(%{user: user})
    end
  end

  def show(%Conn{} = conn, %{"id" => id}) do
    user = Repo.get!(User, id)

    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{user: user})
  end
end
