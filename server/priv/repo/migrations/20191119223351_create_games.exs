defmodule Boardr.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    execute ~s/CREATE EXTENSION "uuid-ossp"/, ~s/DROP EXTENSION "uuid-ossp"/

    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v4()")
      add :title, :string, size: 50
      add :data, :jsonb, null: false

      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end
  end
end
