# frozen_string_literal: true

# Emits only structured conversation content as CSV. Each block includes the
# incoming question that preceded the structured answer.
class Conversations::Exporters::CsvExporter < Conversations::Exporters::BaseExporter
  def render
    items = Conversations::Exporters::StructuredContentDetector
            .new(@messages, message_id: @message_id)
            .structured_items

    CSVSafe.generate(force_quotes: true) do |csv|
      csv << [document_title]
      csv << [generated_at]
      csv << []
      write_items(csv, items)
    end
  end

  private

  def write_items(csv, items)
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

  def item_label(item)
    item[:type] == :table ? 'Tabla' : 'Datos estructurados'
  end

  def question_text(item)
    question = item[:question]
    question.present? ? message_text(question) : ''
  end
end
