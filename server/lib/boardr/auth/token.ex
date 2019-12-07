defmodule Boardr.Auth.Token do
  alias Boardr.Auth.Token.JWT

  def generate(claims) do
    JWT.encode_and_sign claims, create_signer()
  end

  def verify(token) do
    JWT.verify_and_validate token, create_signer()
  end

  defp create_signer() do
    Joken.Signer.create("RS512", %{ "pem" => jwt_private_key() })
  end

  defp jwt_private_key() do
    Application.get_env(:boardr, BoardrWeb.Endpoint)[:jwt_private_key]
  end

  defmodule JWT do
    use Joken.Config

    def token_config() do
      issuer = Application.get_env(:boardr, BoardrWeb.Endpoint)[:jwt_issuer]

      default_claims(
        default_exp: 3600 * 24 * 7,
        skip: [:aud, :iss]
      )
      |> add_claim("aud", fn -> issuer end, &(&1 == issuer))
      |> add_claim("iss", fn -> issuer end, &(&1 == issuer))
    end
  end
end
