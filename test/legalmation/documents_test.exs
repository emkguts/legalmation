defmodule DocumentsTest do
  use Legalmation.DataCase, async: true

  alias Legalmation.Documents

  describe "get_text_and_position" do
    test "extracts text, position, and bold from XML" do
      xml = """
      <document>
      <text><line l="200"><formatting bold="1">This is regular text</formatting></line></text>
      <text><line l="300"><formatting bold=""></formatting></line></text>
      </document>
      """

      expected_output = [
        %{text: "This is regular text", bold: "1", position: 200},
        %{text: "", bold: "", position: 300}
      ]

      assert Documents.get_text_and_position(xml) == expected_output
    end

    test "gets text on same line with different formatting tags" do
      xml = """
      <document>
      <text>
      <line l="200">
      <formatting bold="1">This is regular text</formatting>
      <formatting bold="">Non bold</formatting>
      </line>
      </text>
      </document>
      """

      expected_output = [
        %{text: "This is regular text", bold: "1", position: 200},
        %{text: "Non bold", bold: "", position: 200}
      ]

      assert Documents.get_text_and_position(xml) == expected_output
    end

    test "finds text nested inside other tags" do
      xml = """
      <document>
      <block>
      <region>
      <text>
      <line l="200">
      <formatting bold="1">This is regular text</formatting>
      <formatting bold="">Non bold</formatting>
      </line>
      </text>
      </region>
      </block>
      </document>
      """

      expected_output = [
        %{text: "This is regular text", bold: "1", position: 200},
        %{text: "Non bold", bold: "", position: 200}
      ]

      assert Documents.get_text_and_position(xml) == expected_output
    end

    test "handles empty XML" do
      xml = "<document></document>"
      assert Documents.get_text_and_position(xml) == []
    end
  end

  describe "validate_xml" do
    test "validates a valid xml" do
      assert Documents.validate_xml("<document></document>") == :ok
    end

    test "returns error for bad xml" do
      assert Documents.validate_xml("INVALID") == {:error, :invalid_xml}
    end
  end

  describe "split_by_party" do
    test "splits on specified party" do
      text_list = ["First", "Middle", "Last", "!!jUdgEdfkjsf;", "someone", "else"]

      assert Documents.split_by_party(text_list, "judge") ==
               {Enum.slice(text_list, 0..2), Enum.slice(text_list, 3..5)}
    end

    test "ignores repeat parties" do
      text_list = ["First", "Middle", "Last", "!!jUdgEdfkjsf;", "someone", "judge", "else"]

      assert Documents.split_by_party(text_list, "judge") ==
               {Enum.slice(text_list, 0..2), Enum.slice(text_list, 3..6)}
    end
  end

  describe "drop_until_header" do
    test "ignores non-bolded court" do
      input = [
        %{text: "Nonheader", bold: "1", position: 200},
        %{text: "Superior court", bold: "", position: 300},
        %{text: "Not header", bold: "1", position: 500},
        %{text: "Superior COURT", bold: "1", position: 500},
        %{text: "of Los Angeles", bold: "1", position: 200},
        %{text: "Jane Doe", bold: "", position: 200},
        %{text: "plaintiff", bold: "", position: 200}
      ]

      assert Documents.drop_until_header(input) |> Enum.to_list() == [
               %{text: "Superior COURT", bold: "1", position: 500},
               %{text: "of Los Angeles", bold: "1", position: 200},
               %{text: "Jane Doe", bold: "", position: 200},
               %{text: "plaintiff", bold: "", position: 200}
             ]
    end
  end

  describe "extract_legal_parties" do
    test "extracts the legal parties" do
      [
        {"test/fixtures/A.xml",
         %{
           defendant:
             "HILL-ROM COMPANY, INC., an Indiana ) corporation; and DOES 1 through 100, inclusive, )",
           plaintiff: "ANGELO ANGELES, an individual,"
         }},
        {"test/fixtures/B.xml",
         %{
           defendant: "THIRUMALLAILLC, d/b/a COMMODORE MOTEL, DOES 1-IO, inclusive.,",
           plaintiff: "KUSUMA AMBELGAR,"
         }},
        {"test/fixtures/C.xml",
         %{
           defendant:
             "LAGUARDIA ENTERPRISES, INC., a California Corporation, dba SONSONATE GRILL; and DOES 1 through 25, inclusive,",
           plaintiff: "ALBA ALVARADO, an individual;"
         }}
      ]
      |> Enum.each(fn {filename, expected_out} ->
        output =
          filename
          |> File.read!()
          |> Documents.extract_legal_parties()

        assert output == expected_out
      end)
    end

    test "handles invalid XML" do
      assert Documents.extract_legal_parties("INVALID") == %{
               plaintiff: "INVALID_XML",
               defendant: "INVALID_XML"
             }
    end

    test "handles documents without parties" do
      assert Documents.extract_legal_parties("<document></document>") == %{
               plaintiff: "PLAINTIFF_NOT_FOUND",
               defendant: "DEFENDANT_NOT_FOUND"
             }
    end
  end
end
