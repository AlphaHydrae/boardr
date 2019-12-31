defmodule Asserter do
  import ExUnit.Assertions

  defstruct parent: nil,
            parent_key: nil,
            ref: nil,
            result: nil,
            subject: nil

  def start() do
    AsserterServer.start_link()
  end

  def new(subject) when is_map(subject) do
    verify_on_exit!()
    :ok = AsserterServer.new_map(ref = make_ref(), subject)
    %Asserter{ref: ref, result: %{}, subject: subject}
  end

  def new(subject, %{parent: parent, parent_key: parent_key}) when is_map(subject) and is_map(parent) do
    verify_on_exit!()
    :ok = AsserterServer.new_map(ref = make_ref(), subject)
    %Asserter{parent: parent, parent_key: parent_key, ref: ref, result: %{}, subject: subject}
  end

  def assert_parent(%Asserter{parent: parent, parent_key: parent_key, result: result, subject: subject}) when is_map(subject) do
    %Asserter{parent | result: Map.put(parent.result, parent_key, result)}
  end

  def assert_properties(%Asserter{ref: ref, result: result, subject: subject} = asserter, properties)
      when is_map(subject) and is_map(properties) do
    keys = Map.keys(properties)
    assert Map.take(subject, keys) == properties
    :ok = AsserterServer.assert_map_keys(ref, keys)
    %Asserter{asserter | result: Map.merge(result, properties)}
  end

  def assert_property(%Asserter{ref: ref, subject: subject} = asserter, key)
      when is_map(subject) do
    assert Map.has_key?(subject, key)
    :ok = AsserterServer.assert_map_key(ref, key)
    Asserter.new(subject[key], %{parent: asserter, parent_key: key})
  end

  def assert_property(%Asserter{ref: ref, result: result, subject: subject} = asserter, key, %Regex{} = value)
      when is_map(subject) do
    actual_value = subject[key]
    has_captures = length(Regex.names(value)) >= 1
    assert captures = Regex.named_captures(value, actual_value)
    :ok = AsserterServer.assert_map_key(ref, key)
    %Asserter{asserter | result: Map.put(result, key, if(has_captures, do: captures, else: actual_value))}
  end

  def assert_property(%Asserter{ref: ref, result: result, subject: subject} = asserter, key, value)
      when is_map(subject) do
    assert Map.put(subject, key, value) == subject
    :ok = AsserterServer.assert_map_key(ref, key)
    %Asserter{asserter | result: Map.put(result, key, value)}
  end

  def assert_property(%Asserter{ref: ref, result: result, subject: subject} = asserter, key, callback, args)
      when is_map(subject) and is_function(callback) and is_list(args) do
    value = subject[key]
    callback_result = Kernel.apply(callback, [value | args])

    assert callback_result,
           """
           Expected callback/#{callback |> Function.info() |> Keyword.get(:arity)} to return truthy, got #{
             inspect(callback_result)
           }\narguments:#{
             [value | args]
             |> Enum.with_index()
             |> Enum.map(fn {arg, i} -> "\n\n##{i}\n#{inspect(arg)}" end)
           }
           """

    :ok = AsserterServer.assert_map_key(ref, key)
    %Asserter{asserter | result: Map.put(result, key, callback_result)}
  end

  def assert_property(%Asserter{subject: subject} = asserter, key, callback, arg)
      when is_map(subject) and is_function(callback, 2) and not is_list(arg) do
    assert_property(asserter, key, callback, [arg])
  end

  def ignore_properties(%Asserter{ref: ref, result: result, subject: subject} = asserter, keys)
      when is_map(subject) and is_list(keys) do
    assert Enum.all?(keys, fn key -> Map.has_key?(subject, key) end)
    :ok = AsserterServer.assert_map_keys(ref, keys)
    %Asserter{asserter | result: Map.merge(result, Map.take(subject, keys))}
  end

  defp verify_on_exit!() do
    ExUnit.Callbacks.on_exit(AsserterServer, fn ->
      {:ok, problems} = AsserterServer.verify_on_exit!()

      if length(problems) >= 1 do
        raise Enum.join(problems, "\n\n")
      end
    end)
  end
end
