defmodule Boardr.Auth.Token do
  alias Boardr.Auth.Token.JWT

  def generate(claims) do
    JWT.encode_and_sign claims, create_signer()
  end

  def verify(token) do
    JWT.verify_and_validate token, create_signer()
  end

  defp create_signer() do
    Joken.Signer.create(
      "RS512",
      %{
        "pem" => Application.get_env(:boardr, BoardrWeb.Endpoint)[:jwt_private_key]
      }
    )
  end

  defmodule JWT do
    use Joken.Config
  end
end
