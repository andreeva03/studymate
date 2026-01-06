defmodule Studymate.Repo.Migrations.CreateFlashcards do
  use Ecto.Migration

  def change do
    create table(:flashcards) do
      add :term, :text
      add :definition, :text

      timestamps(type: :utc_datetime)
    end
  end
end
