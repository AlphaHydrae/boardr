defmodule Asserter.Assertions do
  alias Asserter.Error

  def assert_key(asserter, key, callback, opts \\ [])

  def assert_key(
        %Asserter{options: options, subject: subject} = asserter,
        key,
        callback,
        opts
      )
      when is_map(subject) and is_function(callback, 1) and is_list(opts) do
    mark_asserted_keys!(asserter, [key])

    unless Map.has_key?(subject, key) do
      raise Error,
        message: "property #{inspect(key)} is missing",
        subject: subject
    end

    use_raw_value = Keyword.get(opts, :only_value, false)
    value = subject[key]

    effective_options = options
    |> Keyword.merge(opts)
    |> Keyword.drop([:into, :only_value])
    |> Keyword.put(:parent, asserter)

    callback_arg =
      if use_raw_value, do: value, else: Asserter.new(value, effective_options)

    case callback.(callback_arg) do
      %Asserter{result: result} ->
        update_result(asserter, key, result, opts)

      true ->
        update_result(asserter, key, value, opts)

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
        %Asserter{subject: subject} = asserter,
        key,
        %Regex{} = value_regex,
        opts
      )
      when is_map(subject) and is_list(opts) do
    mark_asserted_keys!(asserter, [key])

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
        %Asserter{subject: subject} = asserter,
        key,
        value,
        opts
      )
      when is_map(subject) and is_list(opts) do
    mark_asserted_keys!(asserter, [key])

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
        %Asserter{options: options, subject: subject} = asserter,
        key,
        identical_key,
        opts \\ []
      )
      when is_map(subject) and is_list(opts) do
    mark_asserted_keys!(asserter, [key])

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
        message: "property #{inspect(key)} does not match property #{inspect(identical_key)}",
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
        %Asserter{subject: subject} = asserter,
        properties,
        opts \\ %{}
      )
      when is_map(subject) and is_map(properties) and is_map(opts) do
    keys = Map.keys(properties)
    mark_asserted_keys!(asserter, keys)

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

  def assert_list(value, opts \\ [])

  def assert_list(%Asserter{subject: subject}, opts)
      when not is_list(subject) and is_list(opts) do
    raise Error, message: "value is not a list", subject: subject
  end

  def assert_list(%Asserter{options: options, subject: subject} = asserter, opts)
      when is_list(subject) and is_list(opts) do
    %Asserter{asserter | options: Keyword.merge(options, opts)}
  end

  def assert_list(value, opts) when is_list(value) and is_list(opts) do
    Asserter.new(value, opts)
  end

  def assert_map(value, opts \\ [])

  def assert_map(%Asserter{subject: subject}, opts)
      when not is_map(subject) and is_list(opts) do
    raise Error, message: "value is not a map", subject: subject
  end

  def assert_map(%Asserter{options: options, subject: subject} = asserter, opts)
      when is_map(subject) and is_list(opts) do
    %Asserter{asserter | options: Keyword.merge(options, opts)}
  end

  def assert_map(value, opts) when is_map(value) and is_list(opts) do
    Asserter.new(value, opts)
  end

  def assert_member(%Asserter{subject: subject} = asserter, value, opts \\ []) when is_list(subject) and is_list(opts) do
    #mark_asserted_keys!(asserter, [key])

    unless Enum.member?(subject, value) do
      raise Error,
        message: "value is not a member of the list",
        expected: value,
        subject: subject
    end

    update_result(asserter, value, value, opts)
  end

  def assert_next_member(
        %Asserter{asserted_members: asserted_members, options: options, subject: subject} = asserter,
        callback,
        opts \\ []
      )
      when is_list(asserted_members) and is_list(subject) and is_function(callback, 1) and is_list(opts) do
    # mark_asserted_keys!(asserter, [key])

    remaining_members = subject -- asserted_members
    unless length(remaining_members) >= 1 do
      raise Error,
        message: "list has no more members",
        subject: subject
    end

    use_raw_value = Keyword.get(opts, :only_value, false)
    value = List.first(remaining_members)

    effective_options = options
    |> Keyword.merge(opts)
    |> Keyword.put(:parent, asserter)

    callback_arg =
      if use_raw_value, do: value, else: Asserter.new(value, effective_options)

    case callback.(callback_arg) do
      %Asserter{result: result} ->
        update_result(asserter, result, value, opts)

      true ->
        update_result(asserter, value, value, opts)

      {:ok, callback_result} ->
        update_result(asserter, callback_result, value, opts)

      {:nok, opts} ->
        {callback_message, properties} = Keyword.pop(opts, :message)

        raise Error,
              Keyword.merge(properties,
                message: "next list member #{callback_message}",
                actual: value,
                subject: subject
              )
    end
  end

  # FIXME: check this in server
  def assert_no_more_members(%Asserter{asserted_members: asserted_members, subject: subject} = asserter, opts \\ []) when is_list(asserted_members) and is_list(subject) and is_list(opts) do
    #mark_asserted_keys!(asserter, [key])

    remaining_members = subject -- asserted_members
    unless Enum.empty?(remaining_members) do
      raise Error,
        message: "list has more members",
        actual: subject,
        expected: asserted_members
    end

    asserter
  end

  def ignore_keys(
        %Asserter{subject: subject} = asserter,
        keys
      )
      when is_map(subject) and is_list(keys) do
    mark_asserted_keys!(asserter, keys)

    unless Enum.all?(keys, fn key -> Map.has_key?(subject, key) end) do
      raise Error,
        message: "map does not have some of the specified keys",
        actual: Map.keys(subject),
        expected: keys,
        subject: subject
    end

    asserter
  end

  def on_assert_key_result(%Asserter{options: options} = asserter, callback)
      when is_function(callback) do
    %Asserter{asserter | options: Keyword.put(options, :on_assert_key_result, callback)}
  end

  def on_get_identical_key_value(%Asserter{options: options} = asserter, callback) do
    %Asserter{asserter | options: Keyword.put(options, :get_identical_key_value, callback)}
  end

  defp mark_asserted_keys!(
         %Asserter{asserted_keys: asserted_keys, ref: ref, subject: subject},
         keys
       ) do
    already_asserted_keys = Enum.filter(keys, fn key -> key in asserted_keys end)

    if length(already_asserted_keys) >= 1 do
      raise Error,
        message:
          "assertions have already been made on keys #{
            already_asserted_keys |> Enum.map(&inspect/1) |> Enum.join(", ")
          }",
        asserted_keys: already_asserted_keys,
        subject: subject
    end

    :ok = Asserter.Server.assert_map_keys(self(), ref, keys)
  end

  defp update_result(
         %Asserter{
           asserted_members: asserted_members,
           options: options,
           result: result,
           subject: subject
         } = asserter,
         member_result,
         asserted_member,
         opts
       ) when is_list(asserted_members) and is_list(result) and is_list(subject) and is_list(opts) do
    effective_options = Keyword.merge(options, opts)
    into = Keyword.get(effective_options, :into)

    cond do
      into == false ->
        %Asserter{asserter | asserted_members: asserted_members ++ [asserted_member]}

      not is_nil(into) ->
        raise ":into option can only be nil or false for lists"

      true ->
        %Asserter{asserter | asserted_members: asserted_members ++ [asserted_member], result: result ++ [member_result]}
    end
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
       ) when is_map(result) and is_map(subject) and is_list(opts) do
    effective_options = Keyword.merge(options, opts)
    from = Keyword.get(effective_options, :from)
    into = Keyword.get(effective_options, :into)
    merge = Keyword.get(effective_options, :merge, false)
    # TODO: change callback to conversion from subject key to result key
    callback = Keyword.get(effective_options, :on_assert_key_result)
    value = if v = Keyword.get(effective_options, :value) do
      v
    else
      if from, do: Map.get(result, from, Map.get(subject, from)), else: value
    end

    cond do
      into == false ->
        %Asserter{asserter | asserted_keys: asserted_keys ++ [key]}

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

      # FIXME: when value is a datetime, it is a map
      merge and is_map(result) and is_map(value) ->
        %Asserter{
          asserter
          | asserted_keys: asserted_keys ++ [key],
            result: Map.merge(result, value)
        }

      callback ->
        callback_result = callback.(result, key, value, opts)
        %Asserter{asserter | asserted_keys: asserted_keys ++ [key], result: callback_result}

      true ->
        %Asserter{asserter | asserted_keys: asserted_keys ++ [key]}
    end
  end
end
