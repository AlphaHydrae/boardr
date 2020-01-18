defmodule Boardr.Data do
  def to_list(value, default \\ [])

  def to_list(value, default) when is_list(value) and is_list(default) do
    value
  end

  def to_list(value, default) when is_list(default) do
    if value, do: [value], else: default
  end
end
