defmodule BoardrWeb.UsersView do
  use BoardrWeb, :view

  alias Boardr.Auth.User

  def render("create.json", %{user: %User{} = user}) do
    %{
      createdAt: user.created_at,
      id: user.id,
      name: user.name
    }
  end
end
