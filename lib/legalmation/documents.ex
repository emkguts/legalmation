defmodule Legalmation.Documents do
  import SweetXml

  alias Legalmation.{Documents.Document, Repo}

  @column_tolerance 400

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
         %{plaintiff: plaintiff, defendant: defendant} <- extract_legal_parties(binary),
         {:ok, file} <- insert_document(filename, binary, plaintiff, defendant) do
      {:ok, file}
    end
  end

  def delete_document(fname) do
    with {:ok, file} <- get_document_by_name(fname),
         {:ok, _} <- Repo.delete(file) do
      {:ok, :success}
    end
  end

  def insert_document(filename, file_bin, plaintiff, defendant) do
    %Document{}
    |> Document.changeset(%{
      filename: filename,
      contents: file_bin,
      plaintiff: plaintiff,
      defendant: defendant
    })
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

  def extract_legal_parties(xml_binary) do
    with :ok <- validate_xml(xml_binary),
         text_of_interest <- extract_text_of_interest(xml_binary),
         {plaintiff, [_plaintiff, _vs | tail]} <- split_by_party(text_of_interest, "plaintiff"),
         {defendant, _} <- split_by_party(tail, "defendant") do
      %{plaintiff: Enum.join(plaintiff, " "), defendant: Enum.join(defendant, " ")}
    else
      {:error, :invalid_xml} -> %{plaintiff: "INVALID_XML", defendant: "INVALID_XML"}
      _ -> %{plaintiff: "PLAINTIFF_NOT_FOUND", defendant: "DEFENDANT_NOT_FOUND"}
    end
  end

  def extract_text_of_interest(xml_binary) do
    xml_binary
    |> get_text_and_position()
    |> drop_until_header()
    |> remove_bold()
    |> extract_left_column()
    |> Stream.map(& &1.text)
    |> Stream.map(&trim_after_three_spaces/1)
  end

  defp split_by_party(text_list, party) do
    Enum.split_while(text_list, fn element ->
      not Regex.match?(~r/#{Regex.escape(party)}/i, element)
    end)
  end

  def get_text_and_position(xml_binary) do
    xml_binary
    |> xpath(~x"//line"l,
      formatting: [
        ~x"./formatting"l,
        text: ~x"./text()"s,
        bold: ~x"./@bold"s
      ],
      position: ~x"./@l"i
    )
    |> Enum.flat_map(fn line ->
      Enum.map(line.formatting, fn formatting ->
        %{
          text: formatting.text,
          position: line.position,
          bold: formatting.bold
        }
      end)
    end)
  end

  def validate_xml(binary) do
    try do
      parse(binary, quiet: true)
      :ok
    catch
      :exit, {:fatal, _reason} -> {:error, :invalid_xml}
    end
  end

  def extract_left_column(text_map) do
    cutoff = get_left_col_cutoff(text_map)
    Stream.filter(text_map, fn %{position: p} -> p <= cutoff end)
  end

  def remove_bold(text_map) do
    Stream.filter(text_map, fn %{bold: b} -> b == "" end)
  end

  def drop_until_header(text_map) do
    Stream.drop_while(text_map, fn %{text: t, bold: b} ->
      !(Regex.match?(~r/court/i, t) && b != "")
    end)
  end

  defp get_left_col_cutoff(text_map) do
    text_map
    |> Stream.map(& &1.position)
    |> Enum.min(fn -> 0 end)
    |> Kernel.+(@column_tolerance)
  end

  @doc """
  Truncates a string once three spaces are found, inclusive.
  """
  def trim_after_three_spaces(string) do
    case String.split(string, "   ", parts: 2) do
      [trimmed_string, _rest] -> trimmed_string
      [string] -> string
    end
  end
end
