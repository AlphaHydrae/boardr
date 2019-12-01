defmodule BoardrWeb.IdentitiesView do
  use BoardrWeb, :view

  def render("update.json", %{result: result}) do
    result
  end
end
