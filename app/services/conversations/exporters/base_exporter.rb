# frozen_string_literal: true

class Conversations::Exporters::BaseExporter
  def initialize(data)
    @conversation = data[:conversation]
    @title = data[:title]
    @timezone = data[:timezone]
    @messages = data[:messages]
  end

  def render
    raise NotImplementedError
  end

  protected

  def sender_name(message)
    return 'yo' if message.incoming?

    message.sender&.try(:available_name).presence || message.sender&.try(:name).presence || 'Unknown'
  end

  def message_text(message)
    message.content.to_s
  end

  def formatted_timestamp(message)
    if @timezone.present?
      message.created_at.in_time_zone(@timezone).strftime('%b %d, %Y %I:%M %p %Z')
    else
      message.created_at.strftime('%b %d, %Y %I:%M %p %Z')
    end
  end

  def generated_at
    "Generated: #{Time.zone.now.strftime('%b %d, %Y %I:%M %p %Z')}"
  end

  def attachment_names(message)
    return [] if message.attachments.blank?

    message.attachments.map { |a| a.file.filename.to_s }
  end

  def document_title
    "#{@title} - Conversation ##{@conversation.display_id}"
  end

  # Prawn's built-in fonts only support WinAnsi (Windows-1252). Any character
  # outside that set (emoji, CJK, cyrillic, etc.) raises IncompatibleStringEncoding.
  # Re-encode replacing unsupported characters with '?' so the export never crashes.
  def winansi_safe(text)
    return '' if text.nil?

    text.to_s.encode('Windows-1252', invalid: :replace, undef: :replace, replace: '?')
  end
end
