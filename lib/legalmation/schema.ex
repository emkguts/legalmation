defmodule Legalmation.Schema do
  @moduledoc """
  Defines a schema for Legalmation.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, :binary_id, autogenerate: true}

      def get_fields do
        __schema__(:fields) -- __schema__(:embeds)
      end
    end
  end
end
