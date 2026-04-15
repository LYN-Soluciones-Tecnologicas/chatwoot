# frozen_string_literal: true

class Conversations::ExportService
  SUPPORTED_FORMATS = %w[pdf docx odt html].freeze

  CONTENT_TYPES = {
    'pdf' => 'application/pdf',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'odt' => 'application/vnd.oasis.opendocument.text',
    'html' => 'text/html; charset=utf-8'
  }.freeze

  def initialize(conversation, format)
    @conversation = conversation
    @format = format.to_s.downcase
    raise ArgumentError, "Unsupported format: #{format}" unless SUPPORTED_FORMATS.include?(@format)
  end

  def perform
    exporter_class.new(transcript_data).render
  end

  def filename
    "conversation-#{@conversation.display_id}-#{Time.zone.now.strftime('%Y%m%d')}.#{@format}"
  end

  def content_type
    CONTENT_TYPES[@format]
  end

  private

  def exporter_class
    case @format
    when 'pdf'  then Conversations::Exporters::PdfExporter
    when 'docx' then Conversations::Exporters::DocxExporter
    when 'odt'  then Conversations::Exporters::OdtExporter
    when 'html' then Conversations::Exporters::HtmlExporter
    end
  end

  def transcript_data
    {
      conversation: @conversation,
      title: @conversation.inbox.name,
      timezone: @conversation.inbox.timezone,
      messages: messages_for_transcript
    }
  end

  def messages_for_transcript
    @conversation
      .messages
      .chat
      .includes(:attachments, :sender)
      .order(:created_at)
      .select(&:conversation_transcriptable?)
  end
end
