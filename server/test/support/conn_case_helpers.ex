defmodule BoardrWeb.ConnCaseHelpers do
  alias Boardr.Auth.User
  alias Plug.Conn

  import ExUnit.Assertions
  import Phoenix.ConnTest, only: [post: 3]
  import Plug.Conn, only: [put_req_header: 3]

  @endpoint BoardrWeb.Endpoint

  def generate_token!(%User{id: user_id}) do
    {:ok, token} =
      Boardr.Auth.Token.generate(%{
        scope: "api",
        sub: user_id
      })

    token
  end

  def just_after(unix_timestamp, t2, opts \\ [])

  def just_after(unix_timestamp, %DateTime{} = t2, opts)
      when is_integer(unix_timestamp) and is_list(opts) do
    case DateTime.from_unix(unix_timestamp, :second) do
      {:ok, t1} -> just_after(t1, t2, Keyword.put(opts, :actual_converted, t1))
      _ -> {:nok, [message: "is not a Unix timestamp", expected_just_after: t2]}
    end
  end

  def just_after(iso8601, %DateTime{} = t2, opts) when is_binary(iso8601) and is_list(opts) do
    case DateTime.from_iso8601(iso8601) do
      {:ok, t1, 0} -> just_after(t1, t2, Keyword.put(opts, :actual_converted, t1))
      {:ok, _, _} -> {:nok, [message: "is not UTC", expected_just_after: t2]}
      _ -> {:nok, [message: "is not a valid ISO-8601 date", expected_just_after: t2]}
    end
  end

  def just_after(%DateTime{} = t1, %DateTime{} = t2, opts) when is_list(opts) do
    within = Keyword.get(opts, :within, 1)
    unit = :second

    diff = DateTime.diff(t1, t2, unit)

    cond do
      diff < 0 ->
        {:nok,
         opts
         |> Keyword.take([:actual_converted])
         |> Keyword.merge(message: "is before #{inspect(t2)}", expected_just_after: t2)}

      diff > within ->
        {:nok,
         opts
         |> Keyword.take([:actual_converted])
         |> Keyword.merge(
           message: "is more than #{within} #{unit}s after #{inspect(t2)}",
           expected_just_after: t2
         )}

      true ->
        {:ok, t1}
    end
  end

  def post_json(%Conn{} = conn, path, value) when is_binary(path) do
    conn
    |> put_req_header("content-type", "application/json")
    |> post(path, Jason.encode!(value))
  end

  def test_api_url(path \\ "") do
    "http://localhost:4000/api#{path}"
  end

  def test_api_url_regex(parts) when is_list(parts) do
    ~r/#{
      ([~r/\A/, test_api_url()] ++ parts ++ [~r/\z/])
      |> Enum.map(&test_api_url_regex_part/1)
      |> Enum.join("")
    }/
  end

  def verify_jwt_token!(token) when is_binary(token) do
    jwt_private_key = Application.get_env(:boardr, BoardrWeb.Endpoint)[:jwt_private_key]
    signer = Joken.Signer.create("RS512", %{"pem" => jwt_private_key})
    {:ok, claims} = Joken.verify(token, signer)
    claims
  end

  defp test_api_url_regex_part(part) when is_binary(part) do
    Regex.escape(part)
  end

  defp test_api_url_regex_part(%Regex{} = part) do
    assert Regex.opts(part) == ""
    Regex.source(part)
  end
end
