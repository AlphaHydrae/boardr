defmodule BoardrApi.AuthView do
  use BoardrApi, :view

  alias Boardr.Auth.User
  alias BoardrApi.UsersView

  def render("google.json", %{result: result}) do
    result
  end

  def render("local.json", %{token: token, user: %User{} = user}) when is_binary(token) do
    %{
      _embedded: %{
        'boardr:token': %{
          value: token
        },
        'boardr:user': render_one(user, UsersView, "show.json", as: :user)
      }
    }
  end
end

