# frozen_string_literal: true

# Emits structured conversation content as CSV. Global exports include two
# sections: question/answer pairs first, then extracted structured blocks.
class Conversations::Exporters::CsvExporter < Conversations::Exporters::BaseExporter
  def render
    items = Conversations::Exporters::StructuredContentDetector
            .new(@messages, message_id: @message_id)
            .structured_items

    CSVSafe.generate(force_quotes: true) do |csv|
      csv << [document_title]
      csv << [generated_at]
      csv << []
      message_scoped_export? ? write_structured_items(csv, items) : write_global_items(csv, items)
    end
  end

  private

  def write_global_items(csv, items)
    write_question_answers(csv, items)
    csv << []
    write_structured_items(csv, items)
  end

  def write_question_answers(csv, items)
    csv << ['Preguntas y respuestas']
    csv << %w[Preguntas Respuestas]

    rows = question_answer_rows(items)
    return csv << ['No se encontraron mensajes con tablas o datos estructurados.', ''] if rows.empty?

    rows.each { |row| csv << row }
  end

  def write_structured_items(csv, items)
    csv << ['Datos estructurados'] unless message_scoped_export?
    return write_empty_state(csv) if items.empty?

    items.each_with_index do |item, idx|
      csv << ["Bloque #{idx + 1}", item_label(item)]
      csv << ['Pregunta', question_text(item)]
      csv << ['Mensaje', message_text(item[:message])]
      csv << ['Origen', sender_name(item[:message])]
      csv << ['Fecha', formatted_timestamp(item[:message])]
      csv << []
      csv << item[:headers]
      item[:rows].each { |row| csv << row }
      csv << []
    end
  end

  def write_empty_state(csv)
    csv << ['No se encontraron mensajes con tablas o datos estructurados.']
  end

  def question_answer_rows(items)
    unique_messages(items).map do |item|
      [question_text(item), message_text(item[:message])]
    end
  end

  def unique_messages(items)
    items.each_with_object({}) do |item, indexed|
      indexed[item[:message].id] ||= item
    end.values
  end

  def item_label(item)
    item[:type] == :table ? 'Tabla' : 'Datos estructurados'
  end

  def question_text(item)
    question = item[:question]
    question.present? ? message_text(question) : ''
  end
end
