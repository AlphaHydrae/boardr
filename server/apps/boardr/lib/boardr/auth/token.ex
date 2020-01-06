defmodule Boardr.Auth.Token do
  alias Boardr.Auth.Token.JWT

  def generate(claims) do
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
    Joken.Signer.create("RS512", %{ "pem" => jwt_private_key() })
  end

  defp jwt_private_key() do
    :boardr
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:private_key)
  end

  defmodule JWT do
    use Joken.Config

    @impl Joken.Config
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
