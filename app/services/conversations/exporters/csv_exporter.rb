# frozen_string_literal: true

# Emits the conversation transcript as CSV. When the messages contain
# Markdown tables (detected by StructuredContentDetector) each table is
# rendered as its own block prefixed with metadata; otherwise the file
# falls back to a chronological dump (sender, timestamp, content,
# attachments). CSVSafe is used to neutralise formula-injection vectors.
class Conversations::Exporters::CsvExporter < Conversations::Exporters::BaseExporter
  def render
    detector = Conversations::Exporters::StructuredContentDetector.new(@messages)

    CSVSafe.generate(force_quotes: true) do |csv|
      csv << [document_title]
      csv << [generated_at]
      csv << []

      if detector.structured?
        write_tables(csv, detector.tables)
      else
        write_messages(csv)
      end
    end
  end

  private

  def write_tables(csv, tables)
    tables.each_with_index do |table, idx|
      csv << ["Tabla #{idx + 1}", "Origen: #{table[:sender]}"]
      csv << table[:headers]
      table[:rows].each { |row| csv << row }
      csv << []
    end
  end

  def write_messages(csv)
    csv << %w[Remitente Fecha Mensaje Adjuntos]
    @messages.each do |message|
      csv << [
        sender_name(message),
        formatted_timestamp(message),
        message_text(message),
        attachment_names(message).join(', ')
      ]
    end
  end
end
