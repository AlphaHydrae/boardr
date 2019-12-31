defmodule Asserter.Server do
  use GenServer

  def start_link(_ \\ nil) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def assert_map_key(ref, key) when is_reference(ref) do
    assert_map_keys(ref, [key])
  end

  def assert_map_keys(ref, keys) when is_reference(ref) and is_list(keys) do
    GenServer.call(__MODULE__, {:assert_map_keys, ref, keys})
  end

  def register_map(ref, subject) when is_reference(ref) and is_map(subject) do
    GenServer.call(__MODULE__, {:register_map, ref, subject})
  end

  def verify_on_exit!() do
    GenServer.call(__MODULE__, :verify_on_exit)
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %{maps: %{}}}
  end

  @impl true
  def handle_call(
    {:assert_map_keys, ref, keys},
    _from,
    %{maps: maps} = state
  ) when is_reference(ref) and is_list(keys) do
    current_map = Map.get(maps, ref)
    asserted_keys = MapSet.union(current_map.asserted_keys, MapSet.new(keys))
    {:reply, :ok, Map.put(state, :maps, Map.put(maps, ref, Map.put(current_map, :asserted_keys, asserted_keys)))}
  end

  @impl true
  def handle_call(
    {:register_map, ref, subject},
    _from,
    %{maps: maps} = state
  ) when is_reference(ref) and is_map(subject) do
    new_map = %{asserted_keys: MapSet.new(), subject: subject}
    {:reply, :ok, Map.put(state, :maps, Map.put(maps, ref, new_map))}
  end

  @impl true
  def handle_call(
    :verify_on_exit,
    _from,
    %{maps: maps} = state
  ) do
    problems = Enum.reduce(maps, [], fn {_, %{asserted_keys: asserted_keys, subject: subject}}, acc ->
      keys = subject |> Map.keys() |> Enum.sort()
      asserted_keys = asserted_keys |> MapSet.to_list |> Enum.sort
      if keys != asserted_keys do
        [ "You did not make assertions on keys #{Enum.join(keys -- asserted_keys, ", ")} in map #{inspect(subject)}" | acc ]
      else
        acc
      end
    end)

    {:reply, {:ok, problems}, state}
  end
end
