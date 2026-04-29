# frozen_string_literal: true

require 'cgi'

# Builds a minimal valid .xlsx (Office Open XML SpreadsheetML) package
# without external gems, mirroring the approach used in OdtExporter.
# A single "Transcripción" sheet always contains the chronological dump;
# every Markdown table detected in the messages is added as its own sheet,
# so the CSV/XLSX requirement still produces useful output even when no
# tabular content is present.
class Conversations::Exporters::XlsxExporter < Conversations::Exporters::BaseExporter
  TRANSCRIPT_SHEET = 'Transcripción'
  CONTENT_TYPE_PACKAGE = 'application/vnd.openxmlformats-package.relationships+xml'
  CONTENT_TYPE_WORKBOOK = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml'
  CONTENT_TYPE_WORKSHEET = 'application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml'

  def render
    sheets = build_sheets

    entries = {
      '[Content_Types].xml' => content_types_xml(sheets),
      '_rels/.rels' => root_rels_xml,
      'xl/workbook.xml' => workbook_xml(sheets),
      'xl/_rels/workbook.xml.rels' => workbook_rels_xml(sheets)
    }

    sheets.each_with_index do |sheet, idx|
      entries["xl/worksheets/sheet#{idx + 1}.xml"] = worksheet_xml(sheet[:rows])
    end

    Conversations::Exporters::ZipPackage.new(entries).render
  end

  private

  def build_sheets
    sheets = [{ name: TRANSCRIPT_SHEET, rows: transcript_rows }]

    Conversations::Exporters::StructuredContentDetector.new(@messages).tables.each_with_index do |table, idx|
      sheets << {
        name: safe_sheet_name("Tabla #{idx + 1}"),
        rows: table_rows(table)
      }
    end

    sheets
  end

  def transcript_rows
    rows = [[document_title], [generated_at], [], %w[Remitente Fecha Mensaje Adjuntos]]
    @messages.each do |message|
      rows << [
        sender_name(message),
        formatted_timestamp(message),
        message_text(message),
        attachment_names(message).join(', ')
      ]
    end
    rows
  end

  def table_rows(table)
    [
      ["Tabla extraída del mensaje", "Origen: #{table[:sender]}"],
      [],
      table[:headers]
    ] + table[:rows]
  end

  # Excel sheet names cannot exceed 31 chars and cannot contain : \ / ? * [ ]
  # The backslash is placed first to avoid the [: ... :] POSIX class ambiguity.
  def safe_sheet_name(name)
    sanitized = name.to_s.gsub(%r{[\\/:*?\[\]]}, '_')
    sanitized[0, 31]
  end

  def column_letter(idx)
    letters = +''
    n = idx
    loop do
      letters.prepend(('A'.ord + (n % 26)).chr)
      n = (n / 26) - 1
      break if n.negative?
    end
    letters
  end

  def worksheet_xml(rows)
    body = rows.each_with_index.map do |row, row_idx|
      cells = row.each_with_index.map do |value, col_idx|
        cell_xml(column_letter(col_idx) + (row_idx + 1).to_s, value)
      end.join
      %(<row r="#{row_idx + 1}">#{cells}</row>)
    end.join

    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetData>#{body}</sheetData>
      </worksheet>
    XML
  end

  def cell_xml(reference, value)
    text = value.to_s
    return %(<c r="#{reference}"/>) if text.empty?

    %(<c r="#{reference}" t="inlineStr"><is><t xml:space="preserve">#{escape(text)}</t></is></c>)
  end

  def escape(text)
    CGI.escapeHTML(text.to_s)
  end

  def workbook_xml(sheets)
    sheet_tags = sheets.each_with_index.map do |sheet, idx|
      %(<sheet name="#{escape(sheet[:name])}" sheetId="#{idx + 1}" r:id="rId#{idx + 1}"/>)
    end.join

    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <sheets>#{sheet_tags}</sheets>
      </workbook>
    XML
  end

  def workbook_rels_xml(sheets)
    worksheet_rel_type = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet'
    rels = sheets.each_with_index.map do |_sheet, idx|
      %(<Relationship Id="rId#{idx + 1}" Type="#{worksheet_rel_type}" Target="worksheets/sheet#{idx + 1}.xml"/>)
    end.join

    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">#{rels}</Relationships>
    XML
  end

  def root_rels_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1"
          Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
          Target="xl/workbook.xml"/>
      </Relationships>
    XML
  end

  def content_types_xml(sheets)
    sheet_overrides = sheets.each_with_index.map do |_sheet, idx|
      %(<Override PartName="/xl/worksheets/sheet#{idx + 1}.xml" ContentType="#{CONTENT_TYPE_WORKSHEET}"/>)
    end.join

    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="#{CONTENT_TYPE_PACKAGE}"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/xl/workbook.xml" ContentType="#{CONTENT_TYPE_WORKBOOK}"/>
        #{sheet_overrides}
      </Types>
    XML
  end
end
