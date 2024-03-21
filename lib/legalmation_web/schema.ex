defmodule LegalmationWeb.Schema do
  @moduledoc """
  This module defines the GraphQL schema, resolvers, and middleware of this
  project.
  """

  use Absinthe.Schema

  import_types(Absinthe.Plug.Types)
  import_types(Absinthe.Type.Custom)
  import_types(PortalWeb.Schema.CommonTypes)
  import_types(LegalmationWeb.Schema.DocumentTypes)

  query do
    import_fields(:document_queries)
  end

  mutation do
    import_fields(:document_mutations)
  end
end
