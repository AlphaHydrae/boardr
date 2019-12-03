defmodule BoardrWeb.IdentitiesView do
  use BoardrWeb, :view
  alias Boardr.Auth.Identity

  def render("create.json", assigns) do
    render "show.json", assigns
  end

  def render("index.json", %{identities: identities}) do
    %{
      _embedded: %{
        'boardr:identities': render_many(identities, __MODULE__, "show.json", as: :identity)
      }
    }
    |> put_hal_curies_link()
    |> put_hal_self_link(:identities_url, [:index])
  end

  def render("show.json", %{identity: %Identity{} = identity, token: token}) do
    Map.merge(render("show.json", %{identity: identity}), %{
      _embedded: %{
        'boardr:token': %{
          value: token
        }
      }
    })
  end

  def render("show.json", %{identity: %Identity{} = identity}) do
    %{
      createdAt: identity.created_at,
      email: identity.email,
      emailVerified: identity.email_verified,
      emailVerifiedAt: identity.email_verified_at,
      lastAuthenticatedAt: identity.last_authenticated_at,
      lastSeenAt: identity.last_seen_at,
      provider: identity.provider,
      providerId: identity.provider_id,
      updatedAt: identity.updated_at
    }
    |> omit_nil()
    |> put_hal_links(%{
      collection: %{ href: Routes.identities_url(Endpoint, :index) }
    })
    |> put_hal_self_link(:identities_url, [:show, identity.id])
  end
end
