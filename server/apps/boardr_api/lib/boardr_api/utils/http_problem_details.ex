defmodule BoardrApi.HttpProblemDetails do
  defstruct detail: nil,
            extra_properties: %{},
            instance: nil,
            status: nil,
            title: nil,
            type: nil

  @type t :: %BoardrApi.HttpProblemDetails{
    detail: String.t,
    extra_properties: Map.t,
    instance: String.t,
    status: Atom.t,
    title: String.t,
    type: Atom.t
  }
end
