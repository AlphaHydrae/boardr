defmodule Boardr.Rules.Domain do
  require Record

  @max_board_dimension_size 256

  @type d2 :: record(:d2, col: non_neg_integer, row: non_neg_integer)
  Record.defrecord(:d2, col: nil, row: nil)

  @type game :: record(:game, players: [player], rules: String.t(), settings: map | nil)
  Record.defrecord(:game, players: [], rules: nil, settings: nil)

  @type player :: record(:player, number: pos_integer, settings: map | nil)
  Record.defrecord(:player, number: nil, settings: nil)

  @type take :: record(:take, position: position, player_number: pos_integer, data: map | nil)
  Record.defrecord(:take, :take, position: nil, player_number: nil, data: nil)

  @type action :: take
  @type position :: d2

  defguard is_player_number(value) when is_integer(value) and value >= 1

  defguard is_position_coordinate(value)
           when is_integer(value) and value >= 0 and value < @max_board_dimension_size

  def max_board_dimension_size() do
    @max_board_dimension_size
  end

  def position_from_list([col, row])
      when is_position_coordinate(col) and is_position_coordinate(row) do
    d2(col: col, row: row)
  end

  def position_to_list(d2(col: col, row: row)) do
    [col, row]
  end
end
