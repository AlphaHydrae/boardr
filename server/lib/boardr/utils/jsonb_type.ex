defmodule EctoJsonb do
  use Ecto.Type
  def type, do: :any

  def cast(value) do
    case Jason.encode(value) do
      {:ok, cast_value} -> cast_value
      {:error, _} -> :error
    end
  end

  def load(data) do
    Jason.decode(data)
  end

  def dump(value) do
    Jason.encode(value)
  end
end
