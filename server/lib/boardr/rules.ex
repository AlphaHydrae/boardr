defmodule Boardr.Rules do
  require Record

  @type action :: record(:action, type: Atom.t, position: Integer.t, player_number: Integer.t, data: Map.t)
  Record.defrecord(:action, :action, type: nil, position: nil, player_number: nil, data: %{})

  @type player :: record(:player, number: Integer.t, data: Map.t)
  Record.defrecord(:player, number: nil, data: %{})

  @type game :: record(:game, players: [player], settings: Map.t)
  Record.defrecord(:game, players: [], settings: %{})
end
