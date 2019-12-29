defmodule Boardr.Rules.Factory do
  @callback get_rules(String.t) :: Boardr.Rules.t
end

defmodule Boardr.Rules.DefaultFactory do
  @behaviour Boardr.Rules.Factory

  @impl true
  def get_rules(name) when is_binary(name) do
    case name do
      "tic-tac-toe" -> Boardr.Rules.TicTacToe
    end
  end
end
