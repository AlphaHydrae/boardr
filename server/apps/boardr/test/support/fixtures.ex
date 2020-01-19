defmodule Boardr.Fixtures do
  alias Boardr.{Action,Game,Player}
  alias Boardr.Auth.{Identity,User}
  alias Boardr.Repo

  def action(properties \\ []) when is_list(properties) do
    game_id = Keyword.get_lazy(properties, :game_id, fn ->
      game = Keyword.get_lazy(properties, :game, fn ->
        game(Keyword.get(properties, :game_properties, []))
      end)
      unless is_nil(game), do: game.id, else: nil
    end)

    player_id = Keyword.get_lazy(properties, :player_id, fn ->
      player = Keyword.get_lazy(properties, :player, fn ->
        player(Keyword.get(properties, :player_properties, []))
      end)
      unless is_nil(player), do: player.id, else: nil
    end)

    %Action{
      data: Keyword.get(properties, :data, %{}),
      game_id: game_id,
      player_id: player_id,
      position: Keyword.get(properties, :position, [0, 0]),
      type: Keyword.get(properties, :type, "take"),
      performed_at: Keyword.get_lazy(properties, :performed_at, &DateTime.utc_now/0)
    }
    |> Repo.insert!(returning: [:id])
  end

  def game(properties \\ []) when is_list(properties) do
    creator_id = Keyword.get_lazy(properties, :creator_id, fn ->
      creator = Keyword.get_lazy(properties, :creator, fn ->
        user(Keyword.get(properties, :creator_properties, []))
      end)
      unless is_nil(creator), do: creator.id, else: nil
    end)

    %Game{
      created_at: Keyword.get(properties, :created_at),
      creator_id: creator_id,
      rules: Keyword.get(properties, :rules, "tic-tac-toe"),
      settings: %{},
      state: Keyword.get(properties, :state, "waiting_for_players"),
      updated_at: Keyword.get(properties, :updated_at)
    }
    |> Repo.insert!(returning: [:id])
    |> Repo.preload(:creator)
  end

  def identity(properties \\ []) when is_list(properties) do
    email = Keyword.get_lazy(properties, :email, fn -> "#{Faker.Name.En.first_name()}@example.com" end)
    now = DateTime.utc_now()

    %Identity{
      email: email,
      email_verified: false,
      last_authenticated_at: now,
      last_seen_at: now,
      provider: "local",
      provider_id: String.downcase(email)
    }
    |> Repo.insert!(returning: [:id])
  end

  def player(properties \\ []) when is_list(properties) do
    game_id = Keyword.get_lazy(properties, :game_id, fn ->
      game = Keyword.get_lazy(properties, :game, fn ->
        game(Keyword.get(properties, :game_properties, []))
      end)
      unless is_nil(game), do: game.id, else: nil
    end)

    user_id = Keyword.get_lazy(properties, :user_id, fn ->
      user = Keyword.get_lazy(properties, :user, fn ->
        user(Keyword.get(properties, :user_properties, []))
      end)
      unless is_nil(user), do: user.id, else: nil
    end)

    %Player{
      game_id: game_id,
      number: Keyword.get(properties, :number, 1),
      user_id: user_id
    }
    |> Repo.insert!(returning: [:id])
    # TODO: take those from properties if already there
    |> Repo.preload([:game, :user])
  end

  def user(properties \\ []) when is_list(properties) do
    name = Keyword.get_lazy(properties, :name, fn ->
      "#{Faker.Name.En.first_name()}-#{Faker.Random.Elixir.random_between(10000, 99999)}"
    end)

    %User{
      name: name
    }
    |> Repo.insert!(returning: [:id])
  end
end
