defmodule Boardr.Data do
  @uuid_regexp ~r(^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$)

  def drop_nil(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      if is_nil(value), do: acc, else: Map.put(acc, key, value)
    end)
  end

  def to_list(value, default \\ [])

  def to_list(value, default) when is_list(value) and is_list(default) do
    value
  end

  def to_list(value, default) when is_list(default) do
    if value, do: [value], else: default
  end

  def uuid?(value) when is_binary(value) do
    String.match?(value, @uuid_regexp)
  end

  def uuid?(_value), do: false
end
