defmodule BoardrWeb.ErrorView do
  use BoardrWeb, :view

  def render(_, assigns) do
    %{
      type: "#{Routes.api_url(BoardrWeb.Endpoint, :index)}/problems/#{Map.get(assigns, :error_type) || :unexpected}",
      title: Map.get(assigns, :error_title) || "An unexpected error occurred."
    }
  end
end
