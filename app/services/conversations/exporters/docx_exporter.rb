# frozen_string_literal: true

class Conversations::Exporters::DocxExporter < Conversations::Exporters::BaseExporter
  def render
    title = document_title
    generated_at = "Generated: #{Time.zone.now.strftime('%b %d, %Y %I:%M %p %Z')}"
    rows = build_rows

    Caracal::Document.render do |docx|
      docx.h1 title
      docx.p generated_at do
        color '899096'
        size 18
      end

      rows.each do |row|
        docx.p row[:sender] do
          bold true
          size 22
        end

        docx.p(row[:text]) if row[:text].present?

        if row[:attachments].present?
          docx.p row[:attachments] do
            italic true
            color '555555'
            size 20
          end
        end

        docx.p row[:timestamp] do
          color '899096'
          size 16
        end

        docx.p ''
      end
    end
  end

  private

  def build_rows
    @messages.map do |message|
      attachments = attachment_names(message)
      {
        sender: sender_name(message),
        text: message_text(message),
        attachments: attachments.any? ? "Attachments: #{attachments.join(', ')}" : nil,
        timestamp: formatted_timestamp(message)
      }
    end
  end
end
