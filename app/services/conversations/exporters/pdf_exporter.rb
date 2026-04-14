# frozen_string_literal: true

class Conversations::Exporters::PdfExporter < Conversations::Exporters::BaseExporter
  def render
    pdf = Prawn::Document.new(page_size: 'A4', margin: 40)

    pdf.font_size 16
    pdf.text winansi_safe(document_title), style: :bold
    pdf.move_down 4
    pdf.font_size 11
    pdf.text winansi_safe(generated_at), style: :bold, color: '555555'
    pdf.move_down 16

    @messages.each do |message|
      pdf.font_size 11
      pdf.text winansi_safe(sender_name(message)), style: :bold
      pdf.font_size 10

      text = message_text(message)
      pdf.text winansi_safe(text) if text.present?

      attachments = attachment_names(message)
      if attachments.any?
        pdf.move_down 2
        pdf.text winansi_safe("Attachments: #{attachments.join(', ')}"), style: :italic, color: '555555'
      end

      pdf.move_down 2
      pdf.text winansi_safe(formatted_timestamp(message)), size: 8, color: '899096'
      pdf.move_down 12
    end

    pdf.render
  end
end
