defmodule BoardrWeb.IdentitiesController do
  use BoardrWeb, :controller

  alias Boardr.{Auth,Repo}
  alias Boardr.Auth.Identity

  plug Authenticate when not action in [:create]

  def create(conn, %{"provider" => provider}) do

    claims = %{}

    with {:ok, token} <- Authenticate.get_authorization_token(conn),
         {:ok, identity} <- Auth.ensure_identity(provider, token),
         {:ok, jwt, _} <- Auth.Token.generate(claims) do
      conn
      |> put_identity_created(identity)
      |> put_resp_content_type("application/hal+json")
      |> render(%{identity: identity, token: jwt})
    end
  end

  def index(conn, _assigns) do
    identities = Repo.all(from(i in Identity, order_by: [desc: i.created_at]))
    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{identities: identities})
  end

  def show(conn, %{"id" => id}) do
    identity = Repo.get! Identity, id
    conn
    |> put_resp_content_type("application/hal+json")
    |> render(%{identity: identity})
  end

  defp put_identity_created(conn, %Identity{} = identity) do
    if DateTime.compare(identity.created_at, identity.updated_at) == :eq do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.identities_url(Endpoint, :show, identity.id))
    else
      conn
    end
  end
end
