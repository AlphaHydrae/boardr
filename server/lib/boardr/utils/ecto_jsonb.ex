defmodule EctoJsonb do
  use Ecto.Type
  def type, do: :any

  def cast(value) do
    {:ok, value}
  end

  def load(data) do
    Jason.decode(data)
  end

  def dump(value) do
    Jason.encode(value)
  end
end
