defmodule Boardr.Config do
  def get_required_env(name, error, default \\ nil)
      when is_binary(name) and is_atom(error) and (is_nil(default) or is_binary(default)) do
    value = System.get_env(name)

    cond do
      not is_nil(value) -> {:ok, value}
      not is_nil(default) -> {:ok, default}
      true -> {:error, error}
    end
  end

  # TODO: take protocol(s) as arguments
  def parse_http_url(url, error) when is_binary(url) and is_atom(error) do
    if String.starts_with?(url, ["http://", "https://"]) do
      {:ok, URI.parse(url)}
    else
      {:error, error}
    end
  end

  def parse_integer(value, error, {bounds_error, min, max})
      when is_binary(value) and is_atom(bounds_error) and
             (is_nil(min) or is_integer(min)) and
             (is_nil(max) or is_integer(max)) and
             min <= max do
    case Integer.parse(value) do
      {parsed, ""} -> check_integer_within_bounds(parsed, bounds_error, min, max)
      _ -> {:error, error}
    end
  end

  def parse_port(value, error) do
    parse_integer(value, error, {:port_out_of_bounds, 1, 65535})
  end

  defp check_integer_within_bounds(value, error, min, max)
       when is_integer(value) and is_atom(error) and
              is_integer(min) and is_integer(max) and min <= max do
    cond do
      value >= min and value <= max -> {:ok, value}
      true -> {:error, error, value}
    end
  end
end
