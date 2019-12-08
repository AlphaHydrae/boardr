defmodule BoardrWeb.UsersView do
  use BoardrWeb, :view

  alias Boardr.Auth.User

  def render("create.json", %{token: token, user: %User{} = user}) when is_binary(token) do
    render_one user, __MODULE__, "show.json", as: :user, token: token
  end

  def render("show.json", %{token: token, user: %User{} = user}) when is_binary(token) do
    render_one(user, __MODULE__, "show.json", as: :user)
    |> Map.put(:_embedded, %{
      'boardr:token': %{
        value: token
      }
    })
  end

  def render("show.json", %{user: %User{} = user}) do
    %{
      createdAt: user.created_at,
      id: user.id,
      name: user.name
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:users_url, [:show, user.id])
  end
end
