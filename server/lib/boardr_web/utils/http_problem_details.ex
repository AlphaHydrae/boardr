defmodule BoardrWeb.HttpProblemDetails do
  defstruct type: :unexpected,
            title: "An unexpected error occurred",
            status: :internal_server_error,
            detail: nil,
            instance: nil,
            extra_properties: %{}
end
