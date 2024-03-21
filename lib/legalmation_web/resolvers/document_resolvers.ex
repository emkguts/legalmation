defmodule LegalmationWeb.Resolvers.DocumentResolvers do
  alias Legalmation.Documents

  def list_documents(_parent, _args, _context) do
    {:ok, Documents.list_documents()}
  end

  def get_document_by_name(_, %{filename: fname}, _) do
    Documents.get_document_by_name(fname)
  end

  def upload_document(_parent, %{document: document}, _context) do
    Documents.upload_document(document)
  end

  def delete_document(_, %{filename: fname}, _) do
    Documents.delete_document(fname)
  end
end
