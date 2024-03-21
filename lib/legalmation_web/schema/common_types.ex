defmodule PortalWeb.Schema.CommonTypes do
  @moduledoc """
  Custom GraphQL scalars and low-level types commonly utilized by fields across the GraphQL schema.
  """

  use Absinthe.Schema.Notation

  scalar :uuid, name: "UUID" do
    serialize(&Function.identity/1)
    parse(&parse_uuid/1)
  end

  defp parse_uuid(%Absinthe.Blueprint.Input.String{value: value}) do
    # We use Ecto.UUID.dump to check the validity of the input string, but cast the value back to a
    # string for use in resolvers.
    case Ecto.UUID.dump(value) do
      {:ok, parsed_uuid} -> Ecto.UUID.cast(parsed_uuid)
      :error -> :error
    end
  end

  defp parse_uuid(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_uuid(_) do
    :error
  end
end
