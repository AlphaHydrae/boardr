defmodule BoardrWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use BoardrWeb, :controller
      use BoardrWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: BoardrWeb

      import Plug.Conn
      import Ecto.Query, only: [from: 2]

      alias BoardrWeb.Endpoint, as: Endpoint
      alias BoardrWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/boardr_web/templates",
        namespace: BoardrWeb

      # Import convenience functions from controllers.
      import Phoenix.Controller, only: [view_module: 1]
      import BoardrWeb.ViewHelpers

      alias BoardrWeb.Endpoint, as: Endpoint
      alias BoardrWeb.Router.Helpers, as: Routes
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
