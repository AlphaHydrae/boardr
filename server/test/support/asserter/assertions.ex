defmodule Asserter.Assertions do
  alias Asserter.Error

  def assert_key(asserter, key, callback, opts \\ [])

  def assert_key(
        %Asserter{options: options, ref: ref, subject: subject} = asserter,
        key,
        callback,
        opts
      )
      when is_map(subject) and is_function(callback, 1) and is_list(opts) do
    :ok = Asserter.Server.assert_map_key(ref, key)

    unless Map.has_key?(subject, key) do
      raise Error,
        message: "property #{inspect(key)} is missing",
        subject: subject
    end

    use_raw_value = Keyword.get(opts, :value, false)
    value = subject[key]

    callback_arg =
      if use_raw_value, do: value, else: Asserter.new(value, Keyword.merge(options, opts))

    case callback.(callback_arg) do
      %Asserter{result: result} ->
        update_result(asserter, key, result, opts)

      {:ok, callback_result} ->
        update_result(asserter, key, callback_result, opts)

      {:nok, opts} ->
        {callback_message, properties} = Keyword.pop(opts, :message)

        raise Error,
              Keyword.merge(properties,
                message: "property #{inspect(key)} #{callback_message}",
                actual: subject[key],
                subject: subject
              )
    end
  end

  def assert_key(
        %Asserter{ref: ref, subject: subject} = asserter,
        key,
        %Regex{} = value_regex,
        opts
      )
      when is_map(subject) and is_list(opts) do
    :ok = Asserter.Server.assert_map_key(ref, key)

    value = subject[key]
    captures = Regex.named_captures(value_regex, value)

    unless Map.has_key?(subject, key) and captures do
      raise Error,
        message: "property #{inspect(key)} does not match",
        actual: subject[key],
        expected: value_regex,
        subject: subject
    end

    converted_captures =
      Enum.reduce(captures, %{}, fn {n, v}, acc -> Map.put(acc, String.to_atom(n), v) end)

    result_value =
      if value_regex |> Regex.names() |> length() >= 1, do: converted_captures, else: value

    update_result(asserter, key, result_value, opts)
  end

  def assert_key(
        %Asserter{ref: ref, subject: subject} = asserter,
        key,
        value,
        opts
      )
      when is_map(subject) and is_list(opts) do
    :ok = Asserter.Server.assert_map_key(ref, key)

    unless Map.has_key?(subject, key) and subject[key] === value do
      raise Error,
        message: "property #{inspect(key)} does not match",
        actual: subject[key],
        expected: value,
        subject: subject
    end

    update_result(asserter, key, value, opts)
  end

  def assert_key_absent(
        %Asserter{subject: subject} = asserter,
        key,
        opts \\ []
      )
      when is_map(subject) and is_list(opts) do
    if Map.has_key?(subject, key) do
      raise Error,
        message: "property #{inspect(key)} is present when it should be missing",
        actual: subject[key],
        subject: subject
    end

    update_result(asserter, key, Keyword.get(opts, :value), opts)
  end

  def assert_key_identical(
        %Asserter{options: options, ref: ref, subject: subject} = asserter,
        key,
        identical_key,
        opts \\ []
      )
      when is_map(subject) and is_list(opts) do
    :ok = Asserter.Server.assert_map_key(ref, key)

    unless Map.has_key?(subject, identical_key) do
      raise Error,
        message: "property #{inspect(identical_key)} is absent",
        expected_key: identical_key,
        subject: subject
    end

    value = subject[key]
    identical_value = subject[identical_key]

    unless Map.has_key?(subject, key) and value === identical_value do
      raise Error,
        message: "property #{inspect(key)} does not match",
        actual: value,
        expected: identical_value,
        subject: subject
    end

    effective_options = Keyword.merge(options, opts)

    effective_value =
      if effective_value_callback = Keyword.get(effective_options, :get_identical_key_value) do
        effective_value_callback.(asserter, key, identical_key, effective_options)
      else
        value
      end

    update_result(asserter, key, effective_value, opts)
  end

  def assert_keys(
        %Asserter{ref: ref, subject: subject} = asserter,
        properties,
        opts \\ %{}
      )
      when is_map(subject) and is_map(properties) and is_map(opts) do
    keys = Map.keys(properties)
    :ok = Asserter.Server.assert_map_keys(ref, keys)

    actual = Map.take(subject, keys)

    unless actual == properties do
      raise Error,
        message:
          "properties #{keys |> Enum.map(fn key -> inspect(key) end) |> Enum.join(", ")} do not match",
        actual: actual,
        expected: properties,
        subject: subject
    end

    Enum.reduce(properties, asserter, fn {key, value}, acc ->
      update_result(acc, key, value, Map.get(opts, key, []))
    end)
  end

  def assert_map(value, opts \\ [])

  def assert_map(%Asserter{options: options, subject: subject} = asserter, opts)
      when is_list(opts) do
    unless is_map(subject) do
      raise Error,
        message: "value is not a map",
        subject: subject
    end

    %Asserter{asserter | options: Keyword.merge(options, opts)}
  end

  def assert_map(value, opts) when is_map(value) and is_list(opts) do
    Asserter.new(value, opts)
  end

  def ignore_keys(
        %Asserter{asserted_keys: asserted_keys, ref: ref, subject: subject} = asserter,
        keys
      )
      when is_map(subject) and is_list(keys) do
    unless Enum.all?(keys, fn key -> Map.has_key?(subject, key) end) do
      raise Error,
        message: "map does not have some of the specified keys",
        actual: Map.keys(subject),
        expected: keys,
        subject: subject
    end

    already_asserted_keys = Enum.filter(keys, fn key -> key in asserted_keys end)

    if length(already_asserted_keys) >= 1 do
      raise Error,
        message:
          "cannot ignore keys #{already_asserted_keys |> Enum.map(&inspect/1) |> Enum.join(", ")} on which assertions have already been made",
        asserted_keys: already_asserted_keys,
        ignore_keys: keys,
        subject: subject
    end

    :ok = Asserter.Server.assert_map_keys(ref, keys)
    asserter
  end

  def on_assert_key_result(%Asserter{options: options} = asserter, callback)
      when is_function(callback) do
    %Asserter{asserter | options: Keyword.put(options, :on_assert_key_result, callback)}
  end

  def on_get_identical_key_value(%Asserter{options: options} = asserter, callback) do
    %Asserter{asserter | options: Keyword.put(options, :get_identical_key_value, callback)}
  end

  defp update_result(
         %Asserter{
           asserted_keys: asserted_keys,
           options: options,
           result: result,
           subject: subject
         } = asserter,
         key,
         value,
         opts
       ) do
    effective_options = Keyword.merge(options, opts)
    from = Keyword.get(effective_options, :from)
    into = Keyword.get(effective_options, :into)
    merge = Keyword.get(effective_options, :merge, false)
    callback = Keyword.get(effective_options, :on_assert_key_result)
    value = if from, do: Map.get(result, from, Map.get(subject, from)), else: value

    cond do
      merge and is_map(result) and is_map(value) ->
        %Asserter{asserter | result: Map.merge(result, value)}

      into == false ->
        asserter

      into ->
        %Asserter{
          asserter
          | asserted_keys: asserted_keys ++ [key],
            result:
              Map.put(
                result,
                into,
                value
              )
        }

      callback ->
        callback_result = callback.(result, key, value, opts)
        %Asserter{asserter | asserted_keys: asserted_keys ++ [key], result: callback_result}

      true ->
        %Asserter{asserter | asserted_keys: asserted_keys ++ [key]}
    end
  end
end
