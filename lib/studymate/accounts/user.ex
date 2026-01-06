defmodule Studymate.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  # Using SHA256 for zero-dependency demo. Use Bcrypt in production!
  defp put_password_hash(changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      pw -> put_change(changeset, :password_hash, Base.encode64(:crypto.hash(:sha256, pw)))
    end
  end
end