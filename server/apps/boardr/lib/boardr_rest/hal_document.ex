defmodule BoardrRest.HalDocument do
  def put_curie(doc, name, href, curie_properties \\ %{})

  def put_curie(doc, name, href, :templated)
      when is_map(doc) and (is_atom(name) or is_binary(name)) and is_binary(href) do
    put_curie(doc, name, href, %{"templated" => true})
  end

  def put_curie(doc, name, href, curie_properties)
      when is_map(doc) and is_atom(name) and is_binary(href) and is_map(curie_properties) do
    put_curie(doc, Atom.to_string(name), href, curie_properties)
  end

  def put_curie(doc, name, href, curie_properties)
      when is_map(doc) and is_binary(name) and is_binary(href) and is_map(curie_properties) do
    curie =
      curie_properties
      |> Map.merge(%{
        "name" => name,
        "href" => href
      })

    Map.update(doc, "_links", %{"curies" => [curie]}, fn links ->
      Map.update(links || %{}, "curies", [curie], fn curies ->
        [curie | curies |> Enum.reject(fn c -> c["name"] === name end)]
      end)
    end)
  end

  def put_embedded(doc, rel, doc_or_docs) when is_map(doc) and is_atom(rel) and (is_map(doc_or_docs) or is_list(doc_or_docs)) do
    Map.update(
      doc,
      "_embedded",
      %{Atom.to_string(rel) => doc_or_docs},
      &(Map.put(&1, Atom.to_string(rel), doc_or_docs))
    )
  end

  def put_link(doc, rel, href, link_properties \\ %{})

  def put_link(doc, rel, href, link_properties)
      when is_map(doc) and is_atom(rel) and is_binary(href) and is_map(link_properties) do
    put_link(doc, Atom.to_string(rel), href, link_properties)
  end

  def put_link(doc, rel, href, link_properties)
      when is_map(doc) and is_binary(rel) and is_binary(href) and is_map(link_properties) do
    link = link_properties |> Map.put("href", href)

    Map.update(doc, "_links", %{rel => link}, fn links ->
      Map.put(links || %{}, rel, link)
    end)
  end

  def put_properties(doc, %{"_embedded" => _}) when is_map(doc) do
    raise "_embedded is a reserved HAL property"
  end

  def put_properties(doc, %{"_links" => _}) when is_map(doc) do
    raise "_links is a reserved HAL property"
  end

  def put_properties(doc, properties) when is_map(doc) and is_map(properties) do
    Map.merge(doc, properties)
  end

  def put_property(doc, key, value) when is_map(doc) and is_atom(key) do
    put_property(doc, Atom.to_string(key), value)
  end

  def put_property(doc, "_embedded", _value) when is_map(doc) do
    raise "_embedded is a reserved HAL property"
  end

  def put_property(doc, "_links", _value) when is_map(doc) do
    raise "_links is a reserved HAL property"
  end

  def put_property(doc, key, value) when is_map(doc) and is_binary(key) do
    Map.put(doc, key, value)
  end
end
