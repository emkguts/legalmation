defmodule Legalmation.Repo.Migrations.AddDocumentsTable do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION \"uuid-ossp\""

    create table(:documents) do
      add :filename, :string, null: false
      add :contents, :binary, null: false
      add :plaintiff, :string
      add :defendant, :string
    end

    create unique_index(:documents, :filename)
  end
end
