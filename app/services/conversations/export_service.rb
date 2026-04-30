# frozen_string_literal: true

class Conversations::ExportService
  SUPPORTED_FORMATS = %w[pdf docx odt html csv xlsx].freeze

  CONTENT_TYPES = {
    'pdf' => 'application/pdf',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'odt' => 'application/vnd.oasis.opendocument.text',
    'html' => 'text/html; charset=utf-8',
    'csv' => 'text/csv; charset=utf-8',
    'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  }.freeze

  def initialize(conversation, format, message_id: nil)
    @conversation = conversation
    @format = format.to_s.downcase
    @message_id = message_id.to_s.presence
    @message_id = nil unless @message_id&.match?(/\A\d+\z/)
    raise ArgumentError, "Unsupported format: #{format}" unless SUPPORTED_FORMATS.include?(@format)
  end

  def perform
    exporter_class.new(transcript_data).render
  end

  def filename
    suffix = structured_data_export? ? 'structured-data-' : ''
    message_suffix = structured_data_export? && @message_id.present? ? "message-#{@message_id}-" : ''
    date = Time.zone.now.strftime('%Y%m%d')

    "conversation-#{suffix}#{message_suffix}#{@conversation.display_id}-#{date}.#{@format}"
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
    when 'csv'  then Conversations::Exporters::CsvExporter
    when 'xlsx' then Conversations::Exporters::XlsxExporter
    end
  end

  def structured_data_export?
    %w[csv xlsx].include?(@format)
  end

  def transcript_data
    {
      conversation: @conversation,
      title: @conversation.inbox.name,
      timezone: @conversation.inbox.timezone,
      message_id: @message_id,
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
