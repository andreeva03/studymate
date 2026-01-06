defmodule Studymate.Repo.Migrations.AddCategoryFieldV2 do
  use Ecto.Migration

  def change do
    alter table(:flashcards) do
      # We verify if column exists to avoid errors if it was partially applied
      add_if_not_exists :category, :string, default: "General", null: false
    end

    create_if_not_exists index(:flashcards, [:category])
  end
end