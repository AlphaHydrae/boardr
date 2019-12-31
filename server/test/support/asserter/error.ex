defmodule Asserter.Error do
  defexception [:message, :properties]

  @impl true
  def exception(options) when is_list(options) do
    {message, properties} = Keyword.pop(options, :message)
    {subject, properties} = Keyword.pop(properties, :subject)

    %__MODULE__{
      message:
        String.trim("""
        #{message}
        #{
          properties
          |> Enum.map(fn {key, value} -> "#{key}: #{inspect(value)}" end)
          |> Enum.join("\n")
        }

        #{if subject, do: inspect(subject, pretty: true), else: ""}
        """),
      properties: properties
    }
  end
end
