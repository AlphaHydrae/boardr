defmodule BoardrRest do
  use Rop

  require Record

  @type operation :: record(:operation, type: :create | :retrieve | :update | :destroy, id: binary | list(binary) | nil, entity: binary | map | list | nil, query: binary, options: map)
  Record.defrecord(:operation, :boardr_rest_operation, type: :retrieve, id: nil, entity: nil, query: nil, options: %{})

  defmacro __using__(_) do
    quote do
      use Rop

      require BoardrRest

      alias Boardr.Repo
      alias Ecto.Multi

      import BoardrRest
      import BoardrRest.Auth, only: [authorize: 2]
      import Ecto.Query, only: [from: 2]
    end
  end

  def parse_json_entity(operation(entity: entity, options: options) = op) when is_binary(entity) do
    case Jason.decode(entity) do
      {:ok, decoded} -> {:ok, operation(op, options: Map.put(options, :parsed_entity, decoded))}
      {:error, err} -> {:error, {:malformed_json, err}}
    end
  end

  def parse_json_entity(operation(entity: nil)) do
    {:error, :entity_missing}
  end

  def parse_json_object_entity(operation(options: %{parsed_entity: parsed_entity}) = op) when is_map(parsed_entity) do
    {:ok, op}
  end

  def parse_json_object_entity(operation(options: %{parsed_entity: _parsed_entity})) do
    {:error, :entity_not_an_object}
  end

  def parse_json_object_entity(operation(entity: entity) = op) when is_binary(entity) do
    parse_json_entity(op)
    >>> parse_json_object_entity()
  end
end

defmodule BoardrRest.Service do
  @callback handle_operation(BoardrRest.operation) :: {:ok, any} | {:error, any}
end
