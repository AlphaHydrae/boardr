defmodule BoardrApi.IdentitiesController do
  use BoardrApi, :controller

  alias Boardr.Repo
  alias Boardr.Auth.Identity
  alias BoardrRest.IdentityResources

  require BoardrRest

  def create(%Conn{} = conn, identity_properties) when is_map(identity_properties) do
    with {:ok, %Identity{} = identity} <- rest(conn, IdentityResources, :create) do
      conn
      |> put_identity_created(identity)
      |> render_hal(%{identity: identity})
    end
  end

  # FIXME: require authorization
  def index(%Conn{} = conn, _) do
    identities = Repo.all(from(i in Identity, order_by: [desc: i.created_at]))

    conn
    |> render_hal(%{identities: identities})
  end

  # FIXME: require authorization
  def show(%Conn{} = conn, %{"id" => id}) when is_binary(id) do
    identity = Repo.get!(Identity, id)

    conn
    |> render_hal(%{identity: identity})
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
