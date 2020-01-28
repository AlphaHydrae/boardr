defmodule Asserter do
  defmacro __using__(_opts) do
    quote do
      import Asserter.Assertions
    end
  end

  defstruct asserted_keys: nil,
            asserted_members: nil,
            options: [],
            parent: nil,
            ref: nil,
            result: nil,
            subject: nil

  def start() do
    Asserter.Server.start_link()
  end

  def new(subject, options \\ []) when is_list(options) do
    verify_on_exit!()

    ref = make_ref()

    {asserted_keys, asserted_members, result} =
      cond do
        is_list(subject) ->
          {nil, [], []}

        is_map(subject) ->
          :ok = Asserter.Server.register_map(self(), ref, subject)
          {[], nil, %{}}

        true ->
          {nil, nil, subject}
      end

    {parent, remaining_options} = Keyword.pop(options, :parent)

    %Asserter{
      asserted_keys: asserted_keys,
      asserted_members: asserted_members,
      options: remaining_options,
      parent: parent,
      ref: ref,
      result: result,
      subject: subject
    }
  end

  defp verify_on_exit!() do
    pid = self()
    ExUnit.Callbacks.on_exit(Asserter.Server, fn ->
      {:ok, problems} = Asserter.Server.verify(pid)

      if length(problems) >= 1 do
        raise Enum.join(problems, "\n\n")
      end
    end)
  end
end
