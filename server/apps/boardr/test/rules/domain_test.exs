defmodule Boardr.Rules.DomainTest do
  use ExUnit.Case, async: true

  alias Boardr.Rules.Domain

  require Boardr.Rules.Domain

  test "convert a two-integer list into a two-dimensional position" do
    assert Domain.d2(col: 0, row: 1) = Domain.position_from_list([0, 1])
  end

  test "convert a two-dimensional position into a list" do
    assert [0, 1] = Domain.position_to_list(Domain.d2(col: 0, row: 1))
  end

  test "the max board dimension size is 256" do
    assert 256 = Domain.max_board_dimension_size
  end
end
