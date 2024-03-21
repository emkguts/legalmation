defmodule LegalmationWeb.Schema.DocumentTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias LegalmationWeb.Resolvers.DocumentResolvers

  @desc "A document object representing a file upload and the parsed plaintiff and defendant"
  object :document do
    field :id, non_null(:uuid)
    field :filename, non_null(:string)
    field :plaintiff, :string
    field :defendant, :string
  end

  object :document_queries do
    @desc "List all documents"
    field :list_documents, non_null(list_of(non_null(:document))) do
      resolve(&DocumentResolvers.list_documents/3)
    end

    @desc "Get a document by its filename"
    field :get_document_by_name, non_null(:document) do
      arg(:filename, non_null(:string))
      resolve(&DocumentResolvers.get_document_by_name/3)
    end
  end

  object :document_mutations do
    @desc "Upload an XML document"
    field :upload_document, non_null(:document) do
      arg(:document, non_null(:upload))
      resolve(&DocumentResolvers.upload_document/3)
    end

    @desc "Delete a document by name"
    field :delete_document, type: non_null(:string) do
      arg(:filename, non_null(:string))
      resolve(&DocumentResolvers.delete_document/3)
    end
  end
end
