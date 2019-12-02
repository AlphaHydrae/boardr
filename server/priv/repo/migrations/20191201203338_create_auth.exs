defmodule Boardr.Repo.Migrations.CreateAuth do
  use Ecto.Migration

  def change do
    execute ~s/CREATE TYPE identity_providers AS ENUM ('google');/, ~s/DROP TYPE identity_providers;/

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false, size: 255
      timestamps inserted_at: :created_at, type: :utc_datetime_usec
    end

    create table(:identities, primary_key: false) do
      add :email, :string, size: 255
      add :email_verified, :boolean, default: false, null: false
      add :email_verified_at, :utc_datetime_usec
      add :id, :binary_id, default: fragment("uuid_generate_v4()"), primary_key: true
      add :last_authenticated_at, :utc_datetime_usec, null: false
      add :last_seen_at, :utc_datetime_usec, null: false
      add :provider, :identity_providers, null: false
      add :provider_id, :string, null: false, size: 255
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all, on_update: :update_all)
      timestamps inserted_at: :created_at, type: :utc_datetime_usec
    end

    create constraint(:identities, :google_email_required, check: "provider != 'google' OR email IS NOT NULL")
    create constraint(:identities, :verified_email_required, check: "NOT email_verified OR email IS NOT NULL")
    create constraint(:identities, :verified_at_email_required, check: "email_verified_at IS NULL OR email IS NOT NULL")
    create index(:identities, [:provider, :provider_id], name: :identities_provider_and_id_unique, unique: true)
  end
end
