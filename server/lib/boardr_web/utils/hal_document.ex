defmodule BoardrWeb.HalDocument do
  defstruct _embedded: nil,
            _links: nil,
            properties: %{}

  @type t :: %BoardrWeb.HalDocument{
          _embedded: Map.t() | nil,
          _links: Map.t() | nil,
          properties: Map.t()
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%BoardrWeb.HalDocument{} = value, opts) do
      Jason.Encode.map(BoardrWeb.HalDocument.to_map(value), opts)
    end
  end

  def put_curie(doc, name, href, curie_properties \\ %{})

  def put_curie(%__MODULE__{} = doc, name, href, :templated)
      when (is_atom(name) or is_binary(name)) and is_binary(href) do
    put_curie(doc, name, href, %{templated: true})
  end

  def put_curie(%__MODULE__{} = doc, name, href, curie_properties)
      when is_atom(name) and is_binary(href) and is_map(curie_properties) do
    put_curie(doc, Atom.to_string(name), href, curie_properties)
  end

  def put_curie(%__MODULE__{} = doc, name, href, curie_properties)
      when is_binary(name) and is_binary(href) and is_map(curie_properties) do
    curie =
      curie_properties
      |> Map.merge(%{
        name: name,
        href: href
      })

    Map.update(doc, :_links, %{curies: [curie]}, fn links ->
      Map.update(links || %{}, :curies, [curie], fn curies ->
        [curie | curies |> Enum.reject(fn c -> c.name === name end)]
      end)
    end)
  end

  def new(properties \\ %{}) when is_map(properties) do
    %__MODULE__{properties: properties}
  end

  def put_link(%__MODULE__{} = doc, rel, href, link_properties \\ %{})
      when is_atom(rel) and is_binary(href) and is_map(link_properties) do
    link = link_properties |> Map.put("href", href)

    Map.update(doc, :_links, %{rel => link}, fn links ->
      Map.put(links || %{}, rel, link)
    end)
  end

  def put_property(%__MODULE__{} = doc, key, value) when is_atom(key) do
    put_property(doc, Atom.to_string(key), value)
  end

  def put_property(%__MODULE__{} = doc, key, value) when is_binary(key) do
    %__MODULE__{doc | properties: Map.put(doc.properties, key, value)}
  end

  def to_map(%__MODULE__{_embedded: embedded, _links: links, properties: properties}) do
    properties
    |> put_optional("_embedded", embedded)
    |> put_optional("_links", links)
    |> stringify_keys()
  end

  defp put_optional(map, _key, nil) when is_map(map) do
    map
  end

  defp put_optional(map, key, value) when is_map(map) do
    Map.put(map, key, value)
  end

  defp stringify_keys(value) when is_list(value) do
    Enum.map(value, &stringify_keys/1)
  end

  defp stringify_keys(value) when is_map(value) do
    Enum.reduce(value, %{}, fn {key, value}, acc ->
      stringify_map_key(acc, key, stringify_keys(value))
    end)
  end

  defp stringify_keys(value) do
    value
  end

  defp stringify_map_key(map, key, value) when is_map(map) and is_atom(key) do
    Map.put(map, Atom.to_string(key), stringify_keys(value))
  end

  defp stringify_map_key(map, key, value) when is_map(map) and is_binary(key) do
    Map.put(map, key, value)
  end
end
