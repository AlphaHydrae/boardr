defmodule Boardr.Repo.Migrations.CreateGamesAndPlayers do
  use Ecto.Migration

  def change do
    execute ~s/CREATE TYPE game_states AS ENUM ('waiting_for_players', 'playing', 'draw', 'win');/, ~s/DROP TYPE game_states;/

    create table(:games, primary_key: false) do
      add :creator_id, references(:users, on_delete: :delete_all, on_update: :update_all, type: :binary_id), null: false
      add :id, :binary_id, default: fragment("uuid_generate_v4()"), primary_key: true
      add :rules, :string, null: false, size: 50
      add :settings, :jsonb
      add :state, :game_states, default: "waiting_for_players", null: false
      add :title, :string, size: 50
      timestamps inserted_at: :created_at, type: :utc_datetime_usec
    end

    create table(:players, primary_key: false) do
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all, on_update: :update_all), null: false
      add :id, :binary_id, default: fragment("uuid_generate_v4()"), primary_key: true
      add :number, :smallint, null: false
      add :settings, :jsonb
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all, on_update: :update_all)
      timestamps inserted_at: :created_at, type: :utc_datetime_usec, updated_at: false
    end

    create constraint(:players, :number_min_bound, check: "number >= 1")
    create index(:players, [:game_id, :number], name: :players_game_id_and_number_unique, unique: true)
    create index(:players, [:game_id, :user_id], name: :players_game_id_and_user_id_unique, unique: true)

    create table(:winners, primary_key: false) do
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all, on_update: :update_all), null: false, primary_key: true
      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all, on_update: :update_all), null: false, primary_key: true
    end
  end
end
