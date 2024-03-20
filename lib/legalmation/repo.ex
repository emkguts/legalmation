defmodule Legalmation.Repo do
  use Ecto.Repo,
    otp_app: :legalmation,
    adapter: Ecto.Adapters.Postgres
end
