defmodule BoardrApi.IdentitiesController do
  use BoardrApi, :controller

  alias Boardr.{Auth,Repo}
  alias Boardr.Auth.{Identity,User}

  plug Authenticate, [:'api:identities:index'] when action in [:index]
  plug Authenticate, [:'api:identities:show'] when action in [:show]

  def create(%Conn{} = conn, identity_properties) when is_map(identity_properties) do
    with {:ok, token} <- Authenticate.get_authorization_token(conn, false),
         {:ok, identity} <- Auth.ensure_identity(identity_properties, token),
         claims = create_identity_claims(identity),
         {:ok, jwt} <- Auth.Token.generate(claims) do
      conn
      |> put_identity_created(identity)
      |> render_hal(%{identity: identity, token: jwt})
    end
  end

  def index(%Conn{} = conn, _) do
    identities = Repo.all(from(i in Identity, order_by: [desc: i.created_at]))

    conn
    |> render_hal(%{identities: identities})
  end

  def show(%Conn{} = conn, %{"id" => id}) when is_binary(id) do
    identity = Repo.get! Identity, id

    conn
    |> render_hal(%{identity: identity})
  end

  defp create_identity_claims(%Identity{id: id, user: %User{}}) do
    %{
      scope: "api",
      sub: id
    }
  end

  defp create_identity_claims(%Identity{id: id, user: nil}) do
    %{
      scope: "register",
      sub: id
    }
  end

  defp put_identity_created(%Conn{} = conn, %Identity{} = identity) do
    if DateTime.compare(identity.created_at, identity.updated_at) == :eq do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.identities_url(Endpoint, :show, identity.id))
    else
      conn
    end
  end
end
