defmodule Studymate.StudyTest do
  use Studymate.DataCase

  alias Studymate.Study

  describe "flashcards" do
    alias Studymate.Study.Flashcard

    import Studymate.StudyFixtures

    @invalid_attrs %{term: nil, definition: nil}

    test "list_flashcards/0 returns all flashcards" do
      flashcard = flashcard_fixture()
      assert Study.list_flashcards() == [flashcard]
    end

    test "get_flashcard!/1 returns the flashcard with given id" do
      flashcard = flashcard_fixture()
      assert Study.get_flashcard!(flashcard.id) == flashcard
    end

    test "create_flashcard/1 with valid data creates a flashcard" do
      valid_attrs = %{term: "some term", definition: "some definition"}

      assert {:ok, %Flashcard{} = flashcard} = Study.create_flashcard(valid_attrs)
      assert flashcard.term == "some term"
      assert flashcard.definition == "some definition"
    end

    test "create_flashcard/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Study.create_flashcard(@invalid_attrs)
    end

    test "update_flashcard/2 with valid data updates the flashcard" do
      flashcard = flashcard_fixture()
      update_attrs = %{term: "some updated term", definition: "some updated definition"}

      assert {:ok, %Flashcard{} = flashcard} = Study.update_flashcard(flashcard, update_attrs)
      assert flashcard.term == "some updated term"
      assert flashcard.definition == "some updated definition"
    end

    test "update_flashcard/2 with invalid data returns error changeset" do
      flashcard = flashcard_fixture()
      assert {:error, %Ecto.Changeset{}} = Study.update_flashcard(flashcard, @invalid_attrs)
      assert flashcard == Study.get_flashcard!(flashcard.id)
    end

    test "delete_flashcard/1 deletes the flashcard" do
      flashcard = flashcard_fixture()
      assert {:ok, %Flashcard{}} = Study.delete_flashcard(flashcard)
      assert_raise Ecto.NoResultsError, fn -> Study.get_flashcard!(flashcard.id) end
    end

    test "change_flashcard/1 returns a flashcard changeset" do
      flashcard = flashcard_fixture()
      assert %Ecto.Changeset{} = Study.change_flashcard(flashcard)
    end
  end
end
