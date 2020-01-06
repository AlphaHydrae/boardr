defmodule BoardrApi.AuthView do
  use BoardrApi, :view

  def render("google.json", %{result: result}) do
    result
  end
end

