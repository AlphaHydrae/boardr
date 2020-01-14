defmodule Boardr.Distributed do
  def distribute(module, function, args) when is_atom(module) and is_atom(function) and is_list(args) do
    nodes = Node.list()
    node = if length(nodes) >= 1, do: Enum.random(nodes), else: Node.self()

    {Boardr.TaskSupervisor, node}
    |> Task.Supervisor.async(module, function, args)
    |> Task.await
  end
end
