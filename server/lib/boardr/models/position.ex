defmodule Boardr.Position do
  use Bitwise

  require Record
  Record.defrecord(:d2, __MODULE__, col: 0, row: 0)
  Record.defrecord(:d3, __MODULE__, col: 0, row: 0, depth: 0)

  # Bitmask with 8-byte chunks equal to: 3, 255, 255, 255
  @max 67108863

  def dump(col, row)
      when is_integer(col) and col >= 0 and col <= 255 and
           is_integer(row) and row >= 0 and row <= 255 do
    dump(d2(col: col, row: row))
  end

  def dump(col, row, depth)
      when is_integer(col) and col >= 0 and col <= 255 and
           is_integer(depth) and depth >= 0 and depth <= 255 and
           is_integer(row) and row >= 0 and row <= 255 do
    dump(d3(col: col, depth: depth, row: row))
  end

  def dump({__MODULE__, col, row})
      when is_integer(col) and col >= 0 and col <= 255 and
           is_integer(row) and row >= 0 and row <= 255 do
    row <<< 8
    |> bor(col <<< 16)
    |> bor(2 <<< 24)
  end

  def dump({__MODULE__, col, row, depth})
      when is_integer(col) and col >= 0 and col <= 255 and
           is_integer(depth) and depth >= 0 and depth <= 255 and
           is_integer(row) and row >= 0 and row <= 255 do
    depth
    |> bor(row <<< 8)
    |> bor(col <<< 16)
    |> bor(3 <<< 24)
  end

  def max() do
    @max
  end

  def parse(position) when is_integer(position) and position >= 0 and position <= @max do
    case position >>> 24 do
      2 -> d2(col: position >>> 16 &&& 255, row: position >>> 8 &&& 255)
      3 -> d3(col: position >>> 16 &&& 255, depth: position &&& 255, row: position >>> 8 &&& 255)
    end
  end
end
