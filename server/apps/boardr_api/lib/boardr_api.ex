defmodule BoardrApi do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use BoardrApi, :controller
      use BoardrApi, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: BoardrApi

      alias Boardr.Repo
      alias BoardrApi.Authenticate
      alias BoardrApi.Endpoint
      alias BoardrApi.HttpProblemDetails
      alias BoardrApi.Router
      alias BoardrApi.Router.Helpers, as: Routes
      alias Ecto.Changeset
      alias Ecto.Multi
      alias Plug.Conn

      import BoardrApi.ControllerHelpers
      import BoardrApi.HttpProblemDetailsHelpers, only: [render_problem: 2]
      import Ecto.Query, only: [from: 2]
      import Plug.Conn

      action_fallback BoardrApi.FallbackController
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/boardr_web/templates",
        namespace: BoardrApi

      alias BoardrApi.Endpoint
      alias BoardrApi.Router.Helpers, as: Routes

      import BoardrApi.HalDocument, only: [put_link: 3, put_link: 4]
      import BoardrApi.MapUtils, only: [maybe_put: 4]
      import BoardrApi.ViewHelpers
      import Phoenix.Controller, only: [view_module: 1]
    end
  end

  def plug do
    quote do
      alias BoardrApi.HttpProblemDetails
      alias Plug.Conn

      import BoardrApi.HttpProblemDetailsHelpers
      import BoardrApi.PlugHelpers
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
