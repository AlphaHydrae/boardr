defmodule BoardrWeb.Router do
  use BoardrWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BoardrWeb do
    pipe_through :api
  end
end
