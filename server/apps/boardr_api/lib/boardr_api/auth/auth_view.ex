defmodule BoardrApi.AuthView do
  use BoardrApi, :view

  def render("google.json", %{result: result}) do
    result
  end

  def render("local.json", %{token: token}) when is_binary(token) do
    %{
      _embedded: %{
        'boardr:token': %{
          value: token
        }
      }
    }
  end
end

