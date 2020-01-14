defmodule BoardrRes do
  require Record

  @type context :: record(:context, assigns: map, options: options, representation: list(map) | map | nil)
  Record.defrecord(:context, assigns: %{}, options: nil, representation: nil)

  @type options :: record(:options, authorization_header: list(binary) | nil)
  Record.defrecord(:options, authorization_header: nil)

  defmacro __using__(_) do
    quote do
      use Rop

      require BoardrRes

      alias Boardr.Repo
      alias Ecto.Multi

      import BoardrRes
      import BoardrRes.Auth, only: [authorize: 2]
    end
  end

  def assign(context() = ctx, key, value) when is_atom(key) do
    {:ok, context(ctx, assigns: Map.put(context(ctx, :assigns), key, value))}
  end

  def assign_into(value, context() = ctx, key) when is_atom(key) do
    assign(ctx, key, value)
  end

  def to_context(representation, options() = opts) when is_map(representation) do
    context(options: opts, representation: representation)
  end
end

defmodule BoardrRes.Collection do
  @callback create(map, BoardrRes.options) :: {:ok, struct} | {:error, any}
  @optional_callbacks create: 2
end
