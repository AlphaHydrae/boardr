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

      alias Boardr.Repo
      alias BoardrWeb.Authenticate
      alias BoardrWeb.Endpoint
      alias BoardrWeb.HttpProblemDetails
      alias BoardrWeb.Router
      alias BoardrWeb.Router.Helpers, as: Routes
      alias Ecto.Changeset
      alias Ecto.Multi
      alias Plug.Conn

      import BoardrWeb.ControllerHelpers
      import BoardrWeb.HttpProblemDetailsHelpers, only: [render_problem: 2]
      import Ecto.Query, only: [from: 2]
      import Plug.Conn

      action_fallback BoardrWeb.FallbackController
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/boardr_web/templates",
        namespace: BoardrWeb

      alias BoardrWeb.Endpoint, as: Endpoint
      alias BoardrWeb.Router.Helpers, as: Routes

      import BoardrWeb.HalDocument, only: [put_link: 3, put_link: 4]
      import BoardrWeb.MapUtils, only: [maybe_put: 4]
      import BoardrWeb.ViewHelpers
      import Phoenix.Controller, only: [view_module: 1]
    end
  end

  def plug do
    quote do
      alias BoardrWeb.HttpProblemDetails
      alias Plug.Conn

      import BoardrWeb.HttpProblemDetailsHelpers
      import BoardrWeb.PlugHelpers
      import Plug.Conn
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
