defmodule Studymate.StudyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Studymate.Study` context.
  """

  @doc """
  Generate a flashcard.
  """
  def flashcard_fixture(attrs \\ %{}) do
    {:ok, flashcard} =
      attrs
      |> Enum.into(%{
        definition: "some definition",
        term: "some term"
      })
      |> Studymate.Study.create_flashcard()

    flashcard
  end
end
