defmodule Asserter.Server do
  use GenServer

  def start_link(_ \\ nil) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def assert_map_key(pid, ref, key) when is_pid(pid) and is_reference(ref) do
    assert_map_keys(pid, ref, [key])
  end

  def assert_map_keys(pid, ref, keys) when is_pid(pid) and is_reference(ref) and is_list(keys) do
    GenServer.call(__MODULE__, {:assert_map_keys, pid, ref, keys})
  end

  def register_map(pid, ref, subject)
      when is_pid(pid) and is_reference(ref) and is_map(subject) do
    GenServer.call(__MODULE__, {:register_map, pid, ref, subject})
  end

  def verify(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:verify, pid})
  end

  def verify_on_exit(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:verify_on_exit, pid})
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %{pids: %{maps: %{}}}}
  end

  @impl true
  def handle_call(
        {:assert_map_keys, pid, ref, keys},
        _from,
        %{pids: pids} = state
      )
      when is_pid(pid) and is_reference(ref) and is_list(keys) do
    current_pid_state = Map.get(pids, pid)
    current_pid_maps = current_pid_state.maps
    current_map_state = Map.get(current_pid_maps, ref)
    asserted_keys = MapSet.union(current_map_state.asserted_keys, MapSet.new(keys))

    {:reply, :ok,
     Map.put(
       state,
       :pids,
       Map.put(
         pids,
         pid,
         Map.put(
           current_pid_state,
           :maps,
           Map.put(current_pid_maps, ref, Map.put(current_map_state, :asserted_keys, asserted_keys))
         )
       )
     )}
  end

  @impl true
  def handle_call(
        {:register_map, pid, ref, subject},
        _from,
        %{pids: pids} = state
      )
      when is_pid(pid) and is_reference(ref) and is_map(subject) do
    current_pid_state = Map.get(pids, pid, %{})
    current_pid_maps = Map.get(current_pid_state, :maps, %{})
    new_map = %{asserted_keys: MapSet.new(), subject: subject}
    {
      :reply,
      :ok,
      Map.put(
        state,
        :pids,
        Map.put(
          pids,
          pid,
          Map.put(
            current_pid_state,
            :maps,
            Map.put(current_pid_maps, ref, new_map)
          )
        )
      )
    }
  end

  @impl true
  def handle_call(
        {:verify, pid},
        _from,
        %{pids: pids} = state
      )
      when is_pid(pid) do
    maps = pids |> Map.get(pid) |> Map.get(:maps)

    problems =
      Enum.reduce(maps, [], fn {_, %{asserted_keys: asserted_keys, subject: subject}}, acc ->
        keys = subject |> Map.keys() |> Enum.sort()
        asserted_keys = asserted_keys |> MapSet.to_list() |> Enum.sort()

        if keys != asserted_keys do
          [
            "You did not make assertions on keys #{
              (keys -- asserted_keys) |> Enum.map(&inspect/1) |> Enum.join(", ")
            } in map #{inspect(subject)}"
            | acc
          ]
        else
          acc
        end
      end)

    {:reply, {:ok, problems}, state}
  end
end
