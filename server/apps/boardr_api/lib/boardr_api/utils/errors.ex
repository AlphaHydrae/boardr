defmodule BoardrApi.Errors do
  defmodule MethodNotAllowed do
    @moduledoc """
    Exception raised when the HTTP method is not supported by the target resource
    (e.g. send a DELETE request to a non-deletable resource).
    """
    defexception allowed_methods: [], conn: nil, message: "method not allowed", router: nil

    def exception(%{conn: %Plug.Conn{} = conn, allowed_methods: allowed_methods} = opts) do

      router = Keyword.fetch!(opts, :router)
      path = "/" <> Enum.join(conn.path_info, "/")

      %MethodNotAllowed{
        allowed_methods: allowed_methods,
        conn: conn,
        message: "method #{conn.method} not allowed for #{path} (#{inspect(router)})",
        router: router
      }
    end
  end

  defmodule UnsupportedMediaType do
    @moduledoc """
    Exception raised when the HTTP request body is in a format not supported by
    the target resource (e.g. send XML to a JSON resource).
    """
    defexception conn: nil, message: "unsupported media type", router: nil

    def exception(%{conn: %Plug.Conn{} = conn} = opts) do

      router = Keyword.fetch!(opts, :router)
      path = "/" <> Enum.join(conn.path_info, "/")

      %UnsupportedMediaType{
        conn: conn,
        message: ~s/Content-Type #{Plug.Conn.get_req_header(conn, "content-type")} not supported for #{String.upcase(conn.method)} #{path} (#{inspect(router)})/,
        router: router
      }
    end
  end
end
