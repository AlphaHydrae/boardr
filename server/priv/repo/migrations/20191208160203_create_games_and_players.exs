defmodule Boardr.Repo.Migrations.CreateGamesAndMoves do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :creator_id, references(:users, on_delete: :delete_all, on_update: :update_all, type: :binary_id), null: false
      add :data, :jsonb, null: false
      add :id, :binary_id, default: fragment("uuid_generate_v4()"), primary_key: true
      add :title, :string, size: 50
      timestamps inserted_at: :created_at, type: :utc_datetime
    end

    create table(:players, primary_key: false) do
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all, on_update: :update_all), null: false
      add :id, :binary_id, default: fragment("uuid_generate_v4()"), primary_key: true
      add :number, :smallint, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all, on_update: :update_all)
      timestamps inserted_at: :created_at, type: :utc_datetime, updated_at: false
    end

    create constraint(:players, :number, check: "number >= 0")
    create index(:players, [:game_id, :number], name: :players_game_id_and_number_unique, unique: true)
    create index(:players, [:game_id, :user_id], name: :players_game_id_and_user_id_unique, unique: true)
  end
end
