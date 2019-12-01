defmodule BoardrWeb.AuthView do
  use BoardrWeb, :view

  def render("google.json", %{result: result}) do
    result
  end
end

