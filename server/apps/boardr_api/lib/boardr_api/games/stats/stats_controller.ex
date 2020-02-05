defmodule BoardrApi.StatsController do
  use BoardrApi, :controller

  alias BoardrApi.StatsServer

  def show(%Conn{} = conn, _params) do
    json(conn, StatsServer.stats())
  end
end
