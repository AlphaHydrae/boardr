defmodule BoardrApi.Router do
  use BoardrApi, :router
  use Plug.ErrorHandler

  pipeline :api do
    plug :accepts, ["json"]
    plug :require_json
  end

  scope "/api", BoardrApi do
    pipe_through :api

    get "/", ApiRootController, :index
    get "/stats", StatsController, :show

    scope "/auth" do
      post "/google", AuthController, :google
      post "/local", AuthController, :local
    end

    resources "/games", GamesController, as: :games, name: :game, only: [:create, :index, :show] do
      resources "/actions", Games.ActionsController, only: [:create, :index, :show]
      resources "/board", Games.BoardController, only: [:show], singleton: true
      resources "/players", Games.PlayersController, only: [:create, :show]
      resources "/possible-actions", Games.PossibleActionsController, only: [:index]
    end

    resources "/identities", IdentitiesController, only: [:create, :index, :show]

    resources "/users", UsersController, only: [:create, :show]

    # Method not allowed
    [&post/3, &put/3, &patch/3, &delete/3, &connect/3, &trace/3]
    |> Enum.each(fn verb -> verb.("/*path", MethodNotAllowedController, :match) end)
  end

  def handle_errors(conn, params) do

    {status, title, type, headers} =
      case params do
        %{reason: %Ecto.NoResultsError{}} ->
          {404, "No resource found matching the request URI.", :'resource-not-found', []}
        %{reason: %Phoenix.Router.NoRouteError{}} ->
          {404, "No resource found matching the request URI.", :'resource-not-found', []}
        %{reason: %BoardrApi.Errors.MethodNotAllowed{allowed_methods: allowed_methods}} ->
          {405, "Method not supported for the request URI.", :'method-not-supported', [{"allow", Enum.join(Enum.map(allowed_methods, &String.upcase(Atom.to_string(&1))), ", ")}]}
        %{reason: %Phoenix.NotAcceptableError{}} ->
          {406, "The target resource does not have a representation in the requested format(s).", :'not-acceptable', []}
        %{reason: %BoardrApi.Errors.UnsupportedMediaType{}} ->
          {415, "Content-Type #{get_req_header(conn, "content-type")} is not supported for #{String.upcase(conn.method)} /#{Enum.join(conn.path_info, "/")}.", :'unsupported-media-type', []}
        _ ->
          {500, nil, nil, []}
      end

    conn
      |> put_status(status)
      |> put_resp_content_type("application/problem+json")
      |> merge_resp_headers(headers)
      |> merge_assigns(error_title: title, error_type: type)
      |> put_view(BoardrApi.ErrorView)
      |> render("error.json")
  end

  defp require_json(%{halted: true} = conn, _) do
    conn
  end

  defp require_json(conn, _) do

    content_type = conn |> get_req_header("content-type") |> List.first
    if content_type !== nil and !content_type_is_json(content_type) do
      raise %BoardrApi.Errors.UnsupportedMediaType{conn: conn, router: BoardrApi.Router}
    end

    conn
  end

  defp content_type_is_json(content_type) do
    case ContentType.content_type(content_type) do
      {:ok, _, type, _} -> type === "json" or String.match?(type, ~r/.\+json$/)
      _ -> false
    end
  end
end
