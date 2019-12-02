defmodule BoardrWeb.IdentitiesView do
  use BoardrWeb, :view
  alias Boardr.Auth.Identity

  def render("update.json", %{identity: %Identity{} = identity}) do
    render_identity identity
  end

  defp render_identity(%Identity{} = identity) do
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
    |> omit_nil
  end
end
