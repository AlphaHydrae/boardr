defmodule BoardrWeb.IdentitiesController do
  use BoardrWeb, :controller
  alias Boardr.{Auth,Repo}
  alias Boardr.Auth.Identity

  action_fallback BoardrWeb.FallbackController
  plug :authenticate when action in [:index, :show]

  def create(conn, %{"provider" => provider}) do

    signer = Joken.Signer.create(
      "RS512",
      %{
        "pem" => Application.get_env(:boardr, Endpoint)[:jwt_private_key]
      }
    )

    claims = %{}

    with {:ok, token} <- get_authorization_token(conn),
         {:ok, identity} <- Auth.ensure_identity(provider, token),
         {:ok, jwt, _} <- Auth.Token.encode_and_sign(claims, signer) do
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

  defp authenticate(conn, _) do

    signer = Joken.Signer.create(
      "RS512",
      %{
        "pem" => Application.get_env(:boardr, Endpoint)[:jwt_private_key]
      }
    )

    with {:ok, token} <- get_authorization_token(conn),
         {:ok, claims} <- Auth.Token.verify_and_validate(token, signer) do
      conn
      |> assign(:auth_claims, claims)
    else _ ->
      conn
      |> halt()
      |> render_problem(%HttpProblemDetails{
        title: "You are not authorized to access this resource.",
        type: :authentication_failed,
        status: :unauthorized
      })
    end
  end

  defp get_authorization_token(conn) do
    header_values = get_req_header conn, "authorization"
    header_values_length = length header_values
    cond do
      header_values_length <= 0 -> {:client_error, :auth_header_missing}
      header_values_length >= 2 -> {:client_error, :auth_header_duplicated}
      true -> get_bearer_token(List.first(header_values))
    end
  end

  defp get_bearer_token(header_value) when is_binary(header_value) do
    if [ _, token ] = String.split header_value, " ", parts: 2 do
      {:ok, token}
    else
      {:client_error, :auth_header_malformed}
    end
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
