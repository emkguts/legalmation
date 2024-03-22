defmodule Legalmation.Documents do
  @moduledoc """
  Context file for working with documents
  """

  import SweetXml
  alias Legalmation.{Documents.Document, Repo}

  # How wide we allow the first column to be
  @column_tolerance 400

  @typep text_map :: %{
           text: String.t(),
           bold: String.t(),
           position: integer()
         }
  @typep party_map :: %{
           plaintiff: String.t(),
           defendant: String.t()
         }

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

  @doc """
  Extracts the plaintiff and defendant from an xml binary.
  Assumes that the document will have a bold heading containing the word "court".
  It is expected that directly under the heading, in a left column,
  the plaintiff and defendant are specified in the form "<PLAINTIFF> plaintiff v <DEFENDANT> defendant".
  For other formats, this parser is not guaranteed to correctly extract the legal parties.
  """
  @spec get_text_and_position(binary()) :: party_map()
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

  @doc """
  Extracts text in the left column, immediately under the header.
  """
  @spec extract_text_of_interest(binary()) :: Enumerable.t(String.t())
  def extract_text_of_interest(xml_binary) do
    xml_binary
    |> get_text_and_position()
    |> drop_until_header()
    |> remove_bold()
    |> extract_left_column()
    |> Stream.map(& &1.text)
    |> Stream.map(&trim_after_three_spaces/1)
  end

  @doc """
  Splits a list of strings given a party to look for.
  Assumes that the list is of format ["Name1", "Name2", "Name3", STRING_CONTAINING_PARTY, ...]
  In this case, the function will return {["Name1", "Name2", "Name3"], [STRING_CONTAINING_PARTY, ...]}
  """
  @spec split_by_party([String.t()], String.t()) :: {[String.t()], [String.t()]}
  def split_by_party(text_list, party) do
    Enum.split_while(text_list, fn element ->
      not Regex.match?(~r/#{Regex.escape(party)}/i, element)
    end)
  end

  @doc """
  Parses an xml binary for everything in a text tag. For each text tag, it also finds the left position and bold value.
  """
  @spec get_text_and_position(binary()) :: [text_map()]
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

  @doc """
  Extracts all text in the left column
  """
  @spec extract_left_column(Enumerable.t(text_map())) :: Enumerable.t(text_map())
  def extract_left_column(text_map) do
    cutoff = get_left_col_cutoff(text_map)
    Stream.filter(text_map, fn %{position: p} -> p <= cutoff end)
  end

  @doc """
  Removes bolded text from text_map
  """
  @spec remove_bold(Enumerable.t(text_map())) :: Enumerable.t(text_map())
  def remove_bold(text_map_stream) do
    Stream.filter(text_map_stream, fn %{bold: b} -> b == "" end)
  end

  @doc """
  Drops elements in the textmap until we find the header, which is bold and contains "Court"
  """
  @spec drop_until_header(Enumerable.t(text_map())) :: Enumerable.t(text_map())
  def drop_until_header(text_map_stream) do
    Stream.drop_while(text_map_stream, fn %{text: t, bold: b} ->
      !(Regex.match?(~r/court/i, t) && b != "")
    end)
  end

  @doc """
  Finds the left-most position in the text_map and adds @column_tolerance to determine the cutoff for the left column
  """
  @spec get_left_col_cutoff(Enumerable.t(text_map())) :: integer()
  def get_left_col_cutoff(text_map_stream) do
    text_map_stream
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
