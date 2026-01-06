defmodule Studymate.Accounts do
  import Ecto.Query
  alias Studymate.Repo
  alias Studymate.Accounts.User

  def register_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_email_and_password(email, password) do
    user = Repo.get_by(User, email: email)
    
    # Matching the SHA256 hash from the schema
    if user && user.password_hash == Base.encode64(:crypto.hash(:sha256, password)) do
      {:ok, user}
    else
      {:error, :unauthorized}
    end
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end