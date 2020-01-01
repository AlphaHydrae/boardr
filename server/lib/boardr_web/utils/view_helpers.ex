defmodule BoardrWeb.ViewHelpers do
  alias BoardrWeb.Endpoint, as: Endpoint
  alias BoardrWeb.Router.Helpers, as: Routes

  import BoardrWeb.HalDocument, only: [put_curie: 4, put_link: 4]

  def api_document(properties \\ %{}) when is_map(properties) do
    properties
    |> put_curie(:boardr, "#{Routes.api_root_url(Endpoint, :index)}/rels/{rel}", :templated)
  end

  def put_boardr_link(doc, rel, href, link_properties \\ %{})
      when is_map(doc) and is_binary(href) and is_map(link_properties) do
    put_link(doc, String.to_atom("boardr:#{rel}"), href, link_properties)
  end

  def put_hal_curies_link(map) when is_map(map) do
    put_hal_links(map, %{
      curies: [
        %{
          name: "boardr",
          href: "#{Routes.api_root_url(Endpoint, :index)}/rels/{rel}",
          templated: true
        }
      ]
    })
  end

  def put_hal_links(map, links) when is_map(map) and is_map(links) do
    elem(
      Map.get_and_update(
        map,
        :_links,
        fn existing_links -> {existing_links || %{}, Map.merge(existing_links || %{}, links)} end
      ),
      1
    )
  end

  def put_hal_self_link(map, url_helper, helper_args)
      when is_map(map) and is_atom(url_helper) and is_list(helper_args) do
    put_hal_links(map, %{
      self: %{
        href: apply(Routes, url_helper, [Endpoint | helper_args])
      }
    })
  end

  def omit_nil(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      if is_nil(value), do: acc, else: Map.put(acc, key, value)
    end)
  end
end
