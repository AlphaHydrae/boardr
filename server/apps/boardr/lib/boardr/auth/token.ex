defmodule Boardr.Auth.Token do
  alias Boardr.Auth.Token.JWT
  alias Boardr.Auth.{Identity, User}

  def generate(%Identity{id: identity_id}) when is_binary(identity_id) do
    generate(%{scope: "register", sub: "i:#{identity_id}"})
  end

  def generate(%User{id: user_id}) when is_binary(user_id) do
    generate(%{scope: "api", sub: "u:#{user_id}"})
  end

  def generate(claims) when is_map(claims) do
    case JWT.generate_and_sign(claims, create_signer()) do
      {:ok, jwt, _} -> {:ok, jwt}
      {:error, reason} -> {:error, reason}
      true -> {:error, :unexpected}
    end
  end

  def verify(token) do
    JWT.verify_and_validate token, create_signer()
  end

  defp create_signer() do
    Joken.Signer.create("HS512", jwt_secret())
  end

  defp jwt_secret() do
    :boardr
    |> Application.fetch_env!(Boardr.Auth)
    |> Keyword.fetch!(:secret_key_base)
  end

  defmodule JWT do
    use Joken.Config

    @impl Joken.Config
    def token_config() do
      # FIXME: move this to Boardr.Auth.Token config
      issuer = Application.get_env(:boardr, BoardrApi.Endpoint)[:jwt_issuer]

      default_claims(
        default_exp: 3600 * 24 * 7,
        skip: [:aud, :iss]
      )
      |> add_claim("aud", fn -> issuer end, &(&1 == issuer))
      |> add_claim("iss", fn -> issuer end, &(&1 == issuer))
    end
  end
end
