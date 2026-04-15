# frozen_string_literal: true

class Conversations::Exporters::HtmlExporter < Conversations::Exporters::BaseExporter
  def render
    ApplicationController.renderer.render(
      template: 'conversations/exporters/html_template',
      locals: {
        title: document_title,
        generated_label: generated_at,
        rows: build_rows
      }
    )
  end

  private

  def build_rows
    @messages.map do |message|
      {
        sender: sender_name(message),
        content_html: render_content_html(message),
        attachments: attachment_entries(message),
        timestamp: formatted_timestamp(message)
      }
    end
  end

  def render_content_html(message)
    return nil if message.content.blank?

    ChatwootMarkdownRenderer.new(message.content).render_message
  end

  def attachment_entries(message)
    return [] if message.attachments.blank?

    message.attachments.map { |a| { url: a.file_url, name: a.file.filename.to_s } }
  end
end
