defmodule BoardrWeb.Assertions do
  import ExUnit.Assertions

  alias Boardr.Repo

  import Asserter.Assertions
  import BoardrWeb.ConnCaseHelpers, only: [test_api_url: 1]
  import BoardrWeb.QueryCounter, only: [counted_queries: 1]

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

  def assert_db_queries(query_counter, expected) when is_pid(query_counter) and is_list(expected) do
    assert_db_queries(query_counter, Enum.into(expected, %{}))
  end

  def assert_db_queries(query_counter, expected) when is_pid(query_counter) and is_map(expected) do
    queries = query_counter |> counted_queries
    {transactions, remaining_queries} = Map.split(queries, [:begin, :commit, :rollback])

    # FIXME: check begin, commit & rollback if specified
    {transaction_options, remaining_expected} = Map.split(expected, [:begin, :commit, :max_transactions, :rollback])
    unless Enum.empty?(transactions) do
      assert transactions[:begin] >= 1
      assert transactions[:begin] == transactions[:commit]
      assert transactions[:rollback] == Map.get(transaction_options, :rollback)
      assert transactions[:begin] <= Map.get(transaction_options, :max_transactions, 1)
    end

    {max_selects, remaining_expected} = Map.pop(remaining_expected, :max_selects, 1)
    if Map.has_key?(remaining_queries, :select) do
      assert remaining_queries.select <= max_selects
    end

    remaining_queries = unless Map.has_key?(remaining_expected, :select) do
      Map.delete(remaining_queries, :select)
    else
      remaining_queries
    end

    remaining_expected = Enum.reduce(remaining_expected, %{}, fn {q, n}, acc ->
      if n >= 1 do
        Map.put(acc, q, n)
      else
        acc
      end
    end)

    assert remaining_queries == remaining_expected
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

  def assert_hal_embedded(%Asserter{subject: subject} = asserter, callback, opts \\ [])
      when is_map(subject) and is_function(callback, 1) and is_list(opts) do
    asserter
    |> assert_key(
      "_embedded",
      fn embedded ->
        assert_map(embedded) |> callback.()
      end,
      Keyword.put_new(opts, :merge, true)
    )
  end

  def assert_hal_link(asserter, rel, href, link_properties \\ %{}, opts \\ [])

  def assert_hal_link(
        %Asserter{result: parent_result, subject: subject} = asserter,
        rel,
        href_callback,
        link_properties,
        opts
      )
      when is_map(subject) and is_binary(rel) and is_function(href_callback, 1) and is_map(link_properties) and is_list(opts) do
    asserter
    |> assert_key(rel, fn link ->
      chain =
        assert_map(link)
        |> assert_key("href", href_callback.(parent_result), opts)

      Enum.reduce(link_properties, chain, fn {key, value}, acc ->
        acc |> assert_key(key, value, opts)
      end)
    end)
  end

  def assert_hal_link(
        %Asserter{subject: subject} = asserter,
        rel,
        href,
        link_properties,
        opts
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

  def assert_hal_links(%Asserter{subject: subject} = asserter, callback, opts \\ [])
      when is_map(subject) and is_function(callback, 1) and is_list(opts) do
    asserter
    |> assert_key(
      "_links",
      fn links ->
        assert_map(links) |> callback.()
      end,
      Keyword.put_new(opts, :merge, true)
    )
  end

  def assert_in_db(schema, id, expected)
      when is_atom(schema) and is_binary(id) and is_map(expected) do
    fields = schema.__schema__(:fields)
    assert Map.take(Repo.get!(schema, id), fields) == Map.take(expected, fields)
  end

  defp convert_asserter_result_key(key) when is_binary(key) do
    key |> Inflex.underscore() |> String.to_atom()
  end
end
