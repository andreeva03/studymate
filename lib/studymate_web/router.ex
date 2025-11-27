defmodule StudymateWeb.Router do
  use StudymateWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {StudymateWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", StudymateWeb do
    pipe_through :browser

    # LiveView root route
    live "/", FlashcardLive, :index
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:studymate, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: StudymateWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
