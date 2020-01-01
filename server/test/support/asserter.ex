defmodule Asserter do
  defmacro __using__(_opts) do
    quote do
      import Asserter.Assertions
    end
  end

  defstruct asserted_keys: nil,
            options: [],
            ref: nil,
            result: nil,
            subject: nil

  def start() do
    Asserter.Server.start_link()
  end

  def new(subject, options \\ []) when is_list(options) do
    verify_on_exit!()

    ref = make_ref()

    {asserted_keys, result} =
      cond do
        is_map(subject) ->
          :ok = Asserter.Server.register_map(ref, subject)
          {[], %{}}

        true ->
          {nil, subject}
      end

    %Asserter{
      asserted_keys: asserted_keys,
      options: options,
      ref: ref,
      result: result,
      subject: subject
    }
  end

  defp verify_on_exit!() do
    ExUnit.Callbacks.on_exit(Asserter.Server, fn ->
      {:ok, problems} = Asserter.Server.verify_on_exit!()

      if length(problems) >= 1 do
        raise Enum.join(problems, "\n\n")
      end
    end)
  end
end
