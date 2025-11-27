defmodule Studymate.Repo do
  use Ecto.Repo,
    otp_app: :studymate,
    adapter: Ecto.Adapters.Postgres
end
