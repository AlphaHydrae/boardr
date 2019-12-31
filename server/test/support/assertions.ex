defmodule BoardrWeb.Assertions do
  import ExUnit.Assertions

  alias Boardr.Repo

  def assert_in_db(schema, id, expected) when is_atom(schema) and is_binary(id) and is_map(expected) do
    fields = schema.__schema__(:fields)
    assert Map.take(Repo.get!(schema, id), fields) == Map.take(expected, fields)
  end
end
