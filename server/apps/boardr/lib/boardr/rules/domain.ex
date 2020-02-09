defmodule Boardr.Rules.Domain do
  require Record

  @max_board_dimension_size 256

  @type d2 :: record(:d2, col: non_neg_integer, row: non_neg_integer)
  Record.defrecord(:d2, col: nil, row: nil)

  @type game_state :: :waiting_for_players | :playing | :win | :draw

  @type game :: record(:game, players: [player], rules: binary, settings: map | nil, state: game_state)
  Record.defrecord(:game, players: [], rules: nil, settings: nil, state: :waiting_for_player)

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

  @doc ~S"""
  Converts a list containing a column a row into a boardr 2D position.

  ## Examples

      iex> Boardr.Rules.Domain.position_from_list([0, 2])
      {:d2, 0, 2}
  """
  def position_from_list([col, row])
      when is_position_coordinate(col) and is_position_coordinate(row) do
    d2(col: col, row: row)
  end

  @doc ~S"""
  Converts a boardr 2D position into a list containing a column and row.

  ## Examples

      iex> pos = Boardr.Rules.Domain.d2(col: 1, row: 0)
      iex> Boardr.Rules.Domain.position_to_list(pos)
      [1, 0]
  """
  def position_to_list(d2(col: col, row: row)) do
    [col, row]
  end
end
