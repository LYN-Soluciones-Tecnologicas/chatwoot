# frozen_string_literal: true

# Emits structured conversation content as CSV. Global exports include two
# sections: question/answer pairs first, then extracted structured blocks.
class Conversations::Exporters::CsvExporter < Conversations::Exporters::BaseExporter
  UTF8_BOM = [0xEF, 0xBB, 0xBF].pack('C*').force_encoding(Encoding::UTF_8).freeze

  def render
    items = Conversations::Exporters::StructuredContentDetector
            .new(@messages, message_id: @message_id)
            .structured_items

    csv_data = CSVSafe.generate(force_quotes: true) do |csv|
      csv << csv_row([document_title])
      csv << csv_row([generated_at])
      csv << []
      message_scoped_export? ? write_structured_items(csv, items) : write_global_items(csv, items)
    end

    UTF8_BOM + csv_data
  end

  private

  def write_global_items(csv, items)
    write_question_answers(csv)
    csv << []
    write_structured_items(csv, items)
  end

  def write_question_answers(csv)
    csv << csv_row(['Preguntas y respuestas'])
    csv << csv_row(%w[Preguntas Respuestas])

    rows = question_answer_rows
    return csv << csv_row(['No se encontraron preguntas y respuestas.', '']) if rows.empty?

    rows.each { |row| csv << csv_row(row) }
  end

  def write_structured_items(csv, items)
    csv << csv_row(['Datos estructurados']) unless message_scoped_export?
    return write_empty_state(csv) if items.empty?

    items.each_with_index do |item, idx|
      csv << csv_row(["Bloque #{idx + 1}", item_label(item)])
      csv << csv_row(['Pregunta', question_text(item)])
      csv << csv_row(['Mensaje', message_text(item[:message])])
      csv << csv_row(['Origen', sender_name(item[:message])])
      csv << csv_row(['Fecha', formatted_timestamp(item[:message])])
      csv << []
      csv << csv_row(item[:headers])
      item[:rows].each { |row| csv << csv_row(row) }
      csv << []
    end
  end

  def write_empty_state(csv)
    csv << csv_row(['No se encontraron mensajes con tablas o datos estructurados.'])
  end

  def csv_row(row)
    row.map { |value| csv_value(value) }
  end

  def csv_value(value)
    value.to_s
         .gsub(/[\u00A0\u202F]/, ' ')
         .gsub(/\r\n?|\n/, ' ')
         .gsub(/[[:space:]]+/, ' ')
         .strip
  end

  def item_label(item)
    item[:type] == :table ? 'Tabla' : 'Datos estructurados'
  end

  def question_text(item)
    question = item[:question]
    question.present? ? message_text(question) : ''
  end
end
