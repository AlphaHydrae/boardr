defmodule BoardrApi.UsersView do
  use BoardrApi, :view

  alias Boardr.Auth.User

  def render("create.json", %{user: %User{} = user}) do
    render_one user, __MODULE__, "show.json", as: :user
  end

  def render("show.json", %{user: %User{token: token} = user}) when is_binary(token) do
    render_one(%User{user | token: nil}, __MODULE__, "show.json", as: :user)
    |> Map.put(:_embedded, %{
      'boardr:token': %{
        value: token
      }
    })
  end

  def render("show.json", %{user: %User{token: nil} = user}) do
    %{
      createdAt: user.created_at,
      name: user.name,
      updatedAt: user.updated_at
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:users_url, [:show, user.id])
  end
end
