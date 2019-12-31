defmodule MapChecker do
  defstruct ref: nil,
            result: nil,
            subject: nil

  def start() do
    AsserterServer.start_link()
  end

  def new(subject) when is_map(subject) do
    verify_on_exit!()
    :ok = AsserterServer.new_map(ref = make_ref(), subject)
    %MapChecker{ref: ref, result: %{}, subject: subject}
  end

  def check_hal_property(asserter, key, callback, opts \\ [])

  def check_hal_property(
        %MapChecker{ref: ref, result: result, subject: subject} = asserter,
        key,
        callback,
        opts
      )
      when is_function(callback, 1) do
    :ok = AsserterServer.assert_map_key(ref, key)

    unless Map.has_key?(subject, key) do
      raise MapChecker.Error,
        message: "property #{inspect(key)} is missing",
        source: subject
    end

    case callback.(subject[key]) do
      %MapChecker{result: result} ->
        update_result(asserter, key, result, opts)

      {:ok, callback_result} ->
        update_result(asserter, key, callback_result, opts)

      {:nok, opts} ->
        {callback_message, properties} = Keyword.pop(opts, :message)

        raise MapChecker.Error,
              Keyword.merge(properties,
                message: "property #{inspect(key)} #{callback_message}",
                actual: subject[key],
                source: subject
              )
    end
  end

  def check_hal_property(
        %MapChecker{ref: ref, subject: subject} = asserter,
        key,
        %Regex{} = value_regex,
        opts
      ) do
    :ok = AsserterServer.assert_map_key(ref, key)

    value = subject[key]
    captures = Regex.named_captures(value_regex, value) |> Enum.reduce(%{}, fn {n, v}, acc -> Map.put(acc, String.to_atom(n), v) end)
    unless Map.has_key?(subject, key) and captures do
      raise MapChecker.Error,
        message: "property #{inspect(key)} does not match",
        actual: subject[key],
        expected: value_regex,
        source: subject
    end

    result_value = if Regex.names(value_regex) >= 1, do: captures, else: value
    update_result(asserter, key, result_value, opts)
  end

  def check_hal_property(
        %MapChecker{ref: ref, subject: subject} = asserter,
        key,
        value,
        opts
      ) do
    :ok = AsserterServer.assert_map_key(ref, key)

    unless Map.has_key?(subject, key) and subject[key] === value do
      raise MapChecker.Error,
        message: "property #{inspect(key)} does not match",
        actual: subject[key],
        expected: value,
        source: subject
    end

    update_result(asserter, key, value, opts)
  end

  def check_hal_property_missing(
        %MapChecker{subject: subject} = asserter,
        key,
        value,
        opts \\ []
      ) do
    if Map.has_key?(subject, key) do
      raise MapChecker.Error,
        message: "property #{inspect(key)} is present when it should be missing",
        actual: subject[key],
        source: subject
    end

    update_result(asserter, key, value, opts)
  end

  def check_hal_properties(
        %MapChecker{ref: ref, subject: subject} = asserter,
        properties,
        opts \\ %{}
      )
      when is_map(properties) do
    keys = Map.keys(properties)
    :ok = AsserterServer.assert_map_keys(ref, keys)

    actual = Map.take(subject, keys)

    unless actual == properties do
      raise MapChecker.Error,
        message:
          "properties #{keys |> Enum.map(fn key -> inspect(key) end) |> Enum.join(", ")} do not match",
        actual: actual,
        expected: properties,
        source: subject
    end

    Enum.reduce(properties, asserter, fn {key, value}, acc ->
      update_result(acc, key, value, Map.get(opts, key, []))
    end)
  end

  def ignore_hal_properties(
        %MapChecker{ref: ref, subject: subject} = asserter,
        keys
      )
      when is_map(subject) and is_list(keys) do
    unless Enum.all?(keys, fn key -> Map.has_key?(subject, key) end),
      do:
        raise(MapChecker.Error,
          message: "map does not have some of the specified keys",
          actual: Map.keys(subject),
          expected: keys,
          source: subject
        )

    :ok = AsserterServer.assert_map_keys(ref, keys)
    asserter
  end

  defp update_result(%MapChecker{} = asserter, key, value, opts) when is_atom(opts) do
    update_result(asserter, key, value, into: opts)
  end

  defp update_result(%MapChecker{result: result} = asserter, key, value, opts) do
    from = Keyword.get(opts, :from)
    into = Keyword.get(opts, :into, key)
    merge = Keyword.get(opts, :merge, false)
    cond do
      merge ->
        %MapChecker{asserter | result: Map.merge(result, if(from, do: Map.get(result, from), else: value))}
      into ->
        %MapChecker{
          asserter
          | result:
              Map.put(
                result,
                into,
                if(from, do: Map.get(result, from), else: value)
              )
        }
      true ->
        asserter
    end
  end

  defp verify_on_exit!() do
    ExUnit.Callbacks.on_exit(AsserterServer, fn ->
      {:ok, problems} = AsserterServer.verify_on_exit!()

      if length(problems) >= 1 do
        raise Enum.join(problems, "\n\n")
      end
    end)
  end

  defmodule Error do
    defexception [:message, :properties]

    @impl true
    def exception(options) when is_list(options) do
      {message, properties} = Keyword.pop(options, :message)
      {source, properties} = Keyword.pop(properties, :source)

      %__MODULE__{
        message:
          String.trim("""
          #{message}
          #{
            properties
            |> Enum.map(fn {key, value} -> "#{key}: #{inspect(value)}" end)
            |> Enum.join("\n")
          }

          #{if source, do: inspect(source, pretty: true), else: ""}
          """),
        properties: properties
      }
    end
  end
end
