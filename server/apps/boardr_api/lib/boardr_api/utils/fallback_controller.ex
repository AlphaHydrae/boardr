defmodule BoardrApi.FallbackController do
  use Phoenix.Controller

  alias BoardrApi.HttpProblemDetails
  alias Ecto.Changeset
  alias Plug.Conn

  import BoardrApi.HttpProblemDetailsHelpers

  def call(%Conn{} = conn, {:error, {:auth_error, error}}) do
    render_problem conn, %HttpProblemDetails{
      status: :unauthorized,
      title: "Authentication has failed.",
      type: error
    }
  end

  def call(%Conn{} = conn, {:problem, %HttpProblemDetails{} = problem}) do
    conn
    |> render_problem(problem)
  end

  def call(%Conn{} = conn, {:error, %Changeset{valid?: false} = changeset}) do
    call conn, {:validation_error, changeset}
  end

  def call(%Conn{} = conn, {:error, {:game_error, game_error}}) do
    conn
    |> render_problem(%HttpProblemDetails{
      extra_properties: %{
        gameError: game_error
      },
      status: :conflict,
      title: "The request cannot be completed due to a conflict with the current state of the resource.",
      type: :'game-error'
    })
  end

  # TODO: remove this
  def call(%Conn{} = conn, {:validation_error, %Changeset{} = changeset}) do
    conn
    |> render_problem(%HttpProblemDetails{
      extra_properties: %{
        errors: Enum.map(changeset.errors, fn {key, {message, _}} ->
          %{
            message: message,
            property: "/#{key}"
          }
        end)
      },
      status: :unprocessable_entity,
      title: "The request body contains invalid properties.",
      type: :'validation-error'
    })
  end
end
