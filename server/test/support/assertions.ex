defmodule BoardrWeb.Assertions do
  import ExUnit.Assertions

  alias Boardr.Repo

  import Asserter.Assertions
  import BoardrWeb.ConnCaseHelpers, only: [test_api_url: 1]

  def assert_api_map(value) when is_map(value) do
    assert_map(value)
    # Transform result keys into underscored atoms.
    |> on_assert_key_result(fn result, key, value, _opts ->
      cond do
        is_map(result) ->
          Map.put(result, convert_asserter_result_key(key), value)
      end
    end)
    # Retrieve values of transformed identical keys.
    |> on_get_identical_key_value(fn %Asserter{result: result, subject: subject},
                                     key,
                                     identical_key,
                                     _opts ->
      Map.get(result, convert_asserter_result_key(identical_key), Map.get(subject, key))
    end)
  end

  def assert_hal_curies(%Asserter{subject: subject} = asserter, extra_curies \\ [], opts \\ [])
      when is_map(subject) and is_list(extra_curies) and is_list(opts) do
    asserter
    |> assert_key(
      "curies",
      [
        %{
          "href" => test_api_url("/rels/{rel}"),
          "name" => "boardr",
          "templated" => true
        }
      ] ++ extra_curies
    )
  end

  def assert_hal_link(
        %Asserter{subject: subject} = asserter,
        rel,
        href,
        link_properties \\ %{},
        opts \\ []
      )
      when is_map(subject) and is_binary(rel) and is_map(link_properties) and is_list(opts) do
    asserter
    |> assert_key(rel, fn link ->
      chain =
        assert_map(link)
        |> assert_key("href", href, opts)

      Enum.reduce(link_properties, chain, fn {key, value}, acc ->
        acc |> assert_key(key, value, opts)
      end)
    end)
  end

  def assert_in_db(schema, id, expected) when is_atom(schema) and is_binary(id) and is_map(expected) do
    fields = schema.__schema__(:fields)
    assert Map.take(Repo.get!(schema, id), fields) == Map.take(expected, fields)
  end

  defp convert_asserter_result_key(key) when is_binary(key) do
    key |> Inflex.underscore() |> String.to_atom()
  end
end
