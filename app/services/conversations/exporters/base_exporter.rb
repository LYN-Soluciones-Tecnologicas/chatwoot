# frozen_string_literal: true

class Conversations::Exporters::BaseExporter
  SPANISH_MONTHS = %w[enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre].freeze

  def initialize(data)
    @conversation = data[:conversation]
    @title = data[:title]
    @timezone = data[:timezone]
    @message_id = data[:message_id]
    @messages = data[:messages]
  end

  def render
    raise NotImplementedError
  end

  protected

  def sender_name(message)
    return 'yo' if message.incoming?

    message.sender&.try(:available_name).presence || message.sender&.try(:name).presence || 'Desconocido'
  end

  def message_text(message)
    message.content.to_s
  end

  def formatted_timestamp(message)
    human_date(in_inbox_timezone(message.created_at))
  end

  def generated_at
    "Generado el #{human_date(in_inbox_timezone(Time.current))}"
  end

  def human_date(time)
    day = time.strftime('%-d')
    month = SPANISH_MONTHS[time.month - 1]
    "#{day} de #{month} de #{time.strftime('%Y')} a las #{time.strftime('%H:%M')}"
  end

  def in_inbox_timezone(time)
    @timezone.present? ? time.in_time_zone(@timezone) : time
  end

  def attachment_names(message)
    return [] if message.attachments.blank?

    message.attachments.map { |a| a.file.filename.to_s }
  end

  def document_title
    "#{@title} - Conversación ##{@conversation.display_id}"
  end

  def message_scoped_export?
    @message_id.present?
  end

  # Prawn's built-in fonts only support WinAnsi (Windows-1252). Any character
  # outside that set (emoji, CJK, cyrillic, etc.) raises IncompatibleStringEncoding.
  # Re-encode replacing unsupported characters with '?' so the export never crashes.
  def winansi_safe(text)
    return '' if text.nil?

    text.to_s.encode('Windows-1252', invalid: :replace, undef: :replace, replace: '?')
  end
end
