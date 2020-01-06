defmodule BoardrApi.MapUtils do
  def maybe_put(map, false, _key, _value) when is_map(map), do: map
  def maybe_put(map, true, key, value_callback) when is_map(map) and is_function(value_callback, 0), do: Map.put(map, key, value_callback.())
  def maybe_put(map, true, key, value) when is_map(map), do: Map.put(map, key, value)

  def put_not_empty(map, key, value) when is_map(map), do: maybe_put(map, !Enum.empty?(value), key, value)

  def put_not_nil(map, _key, nil) when is_map(map), do: map
  def put_not_nil(map, key, value) when is_map(map), do: Map.put(map, key, value)
end
