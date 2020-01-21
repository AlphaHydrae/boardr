defmodule BoardrRest do
  use Rop

  import BoardrRest.HalDocument

  require Record

  @type operation :: record(:operation, type: :create | :retrieve | :update | :destroy, id: binary | list(binary) | nil, entity: binary | map | list | nil, query: binary, options: map)
  Record.defrecord(:operation, :boardr_rest_operation, type: :retrieve, id: nil, entity: nil, query: nil, options: %{})

  @type operation_result :: record(:operation_result, type: :ok | :created | :updated, entity: any)
  Record.defrecord(:operation_result, :boardr_rest_operation_result, type: :ok, entity: nil)

  defmacro __using__(_) do
    quote do
      use Rop

      require BoardrRest

      alias Boardr.Repo
      alias Ecto.Multi

      import BoardrRest
      import BoardrRest.Auth, only: [authorize: 2]
      import BoardrRest.HalDocument
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

  def api_hal_document(properties \\ %{}) when is_map(properties) do
    properties
    |> put_curie(:boardr, "#{base_url()}/api/rels/{rel}", :templated)
  end

  def put_boardr_link(doc, rel, href, link_properties \\ %{})
      when is_map(doc) and is_binary(href) and is_map(link_properties) do
    put_link(doc, String.to_atom("boardr:#{rel}"), href, link_properties)
  end

  defp base_url() do
    :boardr
    |> Application.fetch_env!(BoardrRest)
    |> Map.get(:base_url)
  end
end

defmodule BoardrRest.Service do
  @callback handle_operation(BoardrRest.operation) :: {:ok, any} | {:error, any}
end
