defmodule LegalmationWeb.DocumentController do
  use LegalmationWeb, :controller

  alias Legalmation.Documents

  def index(conn, _params) do
    query = """
      query {
        listDocuments {
          id
          filename
          plaintiff
          defendant
        }
      }
    """

    {:ok, %{data: %{"listDocuments" => documents}}} = Absinthe.run(query, LegalmationWeb.Schema)

    render(conn, "index.html",
      documents: documents,
      action: LegalmationWeb.Endpoint.url() <> "/documents"
    )
  end

  def upload(conn, %{"file" => file} = params) do
    with {:ok, _file} <- Documents.upload_document(file) do
      conn
      |> Plug.Conn.put_status(201)
      |> index(params)
    else
      {:error, :filename_taken} ->
        conn
        |> Plug.Conn.put_status(409)
        |> json(%{error: :filename_taken})

      {:error, :not_xml} ->
        conn
        |> Plug.Conn.put_status(422)
        |> json(%{error: :file_not_xml})

      err ->
        conn
        |> Plug.Conn.put_status(500)
        |> json(%{error: err})
    end
  end

  # Fallback if user presses "upload" and without selecting a file.
  def upload(conn, params) do
    index(conn, params)
  end
end
