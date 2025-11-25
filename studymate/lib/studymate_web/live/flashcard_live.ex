defmodule StudymateWeb.FlashcardLive do
  use StudymateWeb, :live_view

  alias Studymate.Study

  @impl true
  def mount(_params, _session, socket) do
    flashcards =
      cond do
        function_exported?(Study, :list_flashcards, 0) ->
          Study.list_flashcards()
          |> Enum.map(fn
            %{question: q, answer: a} -> %{front: q, back: a}
            other -> other
          end)

        true ->
          [
            %{
              front: "What is the key benefit of Elixir's immutable data structures?",
              back: "Concurrency and stability, since data cannot be changed by multiple processes simultaneously."
            },
            %{
              front: "What is Phoenix LiveView?",
              back: "A library that enables rich, real-time user experiences with server-rendered HTML and websockets."
            },
            %{
              front: "What is a GenServer?",
              back: "A behavior module used to implement servers that keep state and handle messages."
            },
            %{
              front: "What is the BEAM?",
              back: "The Erlang VM that runs Elixir code, providing concurrency and fault tolerance."
            },
            %{
              front: "What is pattern matching?",
              back: "Matching values against patterns for expressive control flow and assignments."
            }
          ]
      end

    socket =
      socket
      |> assign(:flashcards, flashcards)
      |> assign(:current_index, 0)
      |> assign(:is_flipped, false)
      |> assign(:completed, false) # initialize completed

    {:ok, socket}
  end

  @impl true
  def handle_event("flip", _params, socket) do
    {:noreply, update(socket, :is_flipped, &(!&1))}
  end

  @impl true
  def handle_event("next", _params, socket) do
    total = length(socket.assigns.flashcards)
    current = socket.assigns.current_index

    if current + 1 < total do
      {:noreply,
       socket
       |> assign(:current_index, current + 1)
       |> assign(:is_flipped, false)}
    else
      # reached end: mark complete
      {:noreply,
       socket
       |> assign(:completed, true)
       |> assign(:is_flipped, false)}
    end
  end

  @impl true
  def handle_event("prev", _params, socket) do
    current = socket.assigns.current_index

    if current > 0 do
      {:noreply,
       socket
       |> assign(:current_index, current - 1)
       |> assign(:is_flipped, false)
       |> assign(:completed, false)}
    else
      {:noreply, socket}
    end
  end
end
