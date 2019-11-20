defmodule BoardrWeb.Router do
  use BoardrWeb, :router
  use Plug.ErrorHandler

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BoardrWeb do
    pipe_through :api

    get "/", ApiController, :index
  end

  def handle_errors(conn, params) do

    {status, title, type} = case params do
      %{reason: %Phoenix.Router.NoRouteError{}} -> {404, "No resource found matching the request URI.", :'resource-not-found'}
      _ -> {500, nil, nil}
    end

    conn
      |> merge_assigns(error_title: title, error_type: type)
      |> put_status(status)
      |> put_resp_content_type("application/problem+json")
      |> put_view(BoardrWeb.ErrorView)
      |> render("error.json")
  end
end
