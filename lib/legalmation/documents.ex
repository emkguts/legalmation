defmodule Legalmation.Documents do
  alias Legalmation.{Documents.Document, Repo}

  def list_documents() do
    Document
    |> Document.order_by_filename()
    |> Repo.all()
  end

  def get_document_by_name(fname) do
    Document
    |> Document.where_filename(fname)
    |> Repo.one()
    |> case do
      nil -> {:error, :document_not_found}
      file -> {:ok, file}
    end
  end

  def upload_document(%{path: path, filename: filename}) do
    with :ok <- validate_filetype(filename),
         :ok <- validate_unique_file(filename),
         {:ok, binary} <- File.read(path),
         {:ok, file} <- insert_document(filename, binary) do
      {:ok, file}
    end
  end

  def delete_document(fname) do
    with {:ok, file} <- get_document_by_name(fname),
         {:ok, _} <- Repo.delete(file) do
      {:ok, :success}
    end
  end

  def insert_document(filename, file_bin) do
    %Document{}
    |> Document.changeset(%{filename: filename, contents: file_bin})
    |> Repo.insert()
  end

  defp validate_filetype(filename) do
    (Regex.match?(~r/.*.xml$/, filename) && :ok) || {:error, :not_xml}
  end

  defp validate_unique_file(filename) do
    Document
    |> Document.where_filename(filename)
    |> Repo.exists?()
    |> then(&((!&1 && :ok) || {:error, :filename_taken}))
  end
end
