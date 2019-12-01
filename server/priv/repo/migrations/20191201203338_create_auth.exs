defmodule Boardr.Repo.Migrations.CreateAuth do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :name, :string, null: false
      timestamps(inserted_at: :created_at, type: :utc_datetime)
    end

    create table(:identities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all, on_update: :update_all)
      add :last_authenticated_at, :utc_datetime, null: false
      add :last_seen_at, :utc_datetime, null: false
      timestamps(inserted_at: :created_at, updated_at: false, type: :utc_datetime)
    end
  end
end
