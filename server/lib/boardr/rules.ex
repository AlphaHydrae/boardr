defmodule Boardr.Rules do
  alias Boardr.Rules.Domain

  @callback board(Domain.game, map | nil) :: {:ok, []}
  @callback play(Domain.action, Domain.game, map | nil) ::
              {:ok, Domain.action, map | nil, :playing}
              | {:ok, Domain.action, map | nil, :draw}
              | {:ok, Domain.action, map | nil, {:win, [pos_integer]}}
  @callback possible_actions(map, Domain.game, map | nil) :: {:ok, [Domain.action]}

  @type t :: module
end
