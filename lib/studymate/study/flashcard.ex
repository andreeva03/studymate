defmodule Studymate.Study.Flashcard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "flashcards" do
    field :term, :string
    field :definition, :string
    field :category, :string, default: "General"

    timestamps()
  end

  @doc false
  def changeset(flashcard, attrs) do
    flashcard
    |> cast(attrs, [:term, :definition, :category])
    |> validate_required([:term, :definition, :category])
  end
end