defmodule Legalmation.Documents.Document do
  use Legalmation.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "documents" do
    field :filename, :string
    field :contents, :binary
    field :plaintiff, :string
    field :defendant, :string
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, get_fields())
    |> validate_required([
      :filename,
      :contents
    ])
    |> unique_constraint(:filename)
  end

  def order_by_filename(query), do: order_by(query, [d], d.filename)

  def where_filename(query, fname), do: where(query, filename: ^fname)
end
