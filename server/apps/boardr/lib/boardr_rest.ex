defmodule BoardrRest do
  require Record

  @type authorization ::
          {:identity, binary, scopes}
          | {:bearer_token, binary}
          | {:user, binary, scopes}

  @type scopes :: list(binary)

  @type http_request ::
          record(
            :http_request,
            body: binary | nil,
            query_string: binary | nil
          )
  Record.defrecord(
    :http_request,
    :boardr_rest_http_request_data,
    body: nil,
    query_string: nil
  )

  @type operation ::
          record(
            :operation,
            type: :create | :retrieve | :update | :destroy,
            id: binary | list(binary) | nil,
            data: http_request,
            authorization: authorization | nil,
            options: map
          )
  Record.defrecord(
    :operation,
    :boardr_rest_operation,
    type: :retrieve,
    id: nil,
    data: nil,
    authorization: nil,
    options: %{}
  )

  defmacro __using__(_) do
    quote do
      require BoardrRest

      alias Boardr.Repo
      alias Ecto.Multi

      import BoardrRest
      import BoardrRest.Auth, only: [authorize: 3]
      import Ecto.Query, only: [from: 2]
    end
  end

  def parse_json_object(entity) when is_binary(entity) do
    case parse_json_entity(entity) do
      {:ok, %{} = parsed} -> {:ok, parsed}
      {:ok, _} -> {:error, :wrong_json_value_type}
      {:error, err} -> {:error, err}
    end
  end

  defp parse_json_entity(entity) when is_binary(entity) do
    case Jason.decode(entity) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, err} -> {:error, {:malformed_json, err}}
    end
  end
end

defmodule BoardrRest.Resources do
  @callback handle_operation(BoardrRest.operation()) :: {:ok, any} | {:error, any}
end
