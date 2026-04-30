# frozen_string_literal: true

require 'json'

# Scans transcript messages for structured content so CSV / XLSX exports can
# contain only data blocks and the incoming question that prompted each one.
class Conversations::Exporters::StructuredContentDetector
  JSON_FENCE = /```(?:json)?\s*\n(.*?)\n```/im

  def initialize(messages, message_id: nil)
    @messages = messages
    @message_id = message_id.to_s.presence
  end

  def structured_items
    @structured_items ||= extract_structured_items
  end

  def tables
    structured_items.select { |item| item[:type] == :table }
  end

  def structured?
    structured_items.any?
  end

  private

  def extract_structured_items
    last_question = nil

    @messages.flat_map do |message|
      last_question = message if question_message?(message)
      next [] unless target_message?(message)

      extract_from(message, last_question)
    end
  end

  def target_message?(message)
    @message_id.blank? || message.id.to_s == @message_id
  end

  def question_message?(message)
    message.incoming? && message.content.present?
  end

  def extract_from(message, question)
    content = message.content.to_s
    return [] if content.empty?

    markdown_tables(content, message, question) +
      json_blocks(content, message, question)
  end

  def markdown_tables(content, message, question)
    lines = content.lines.map { |line| line.sub(/\r?\n\z/, '') }
    found = []
    index = 0

    while index < lines.length
      if table_row?(lines[index]) && index + 1 < lines.length && separator_row?(lines[index + 1])
        header = parse_row(lines[index])
        data_start = index + 2
        data_end = data_start
        data_end += 1 while data_end < lines.length && table_row?(lines[data_end])

        rows = lines[data_start...data_end].map { |line| parse_row(line) }
        if usable_table?(header, rows)
          found << {
            type: :table,
            headers: header,
            rows: rows,
            message: message,
            question: question
          }
        end
        index = data_end
      else
        index += 1
      end
    end

    found
  end

  def json_blocks(content, message, question)
    json_candidates(content).filter_map do |payload|
      table = table_from_json(payload)
      next if table.blank?

      table.merge(type: :structured_data, message: message, question: question)
    end
  end

  def json_candidates(content)
    candidates = content.scan(JSON_FENCE).flatten
    stripped = content.strip
    candidates << stripped if stripped.start_with?('{', '[')
    candidates.uniq
  end

  def table_from_json(payload)
    value = JSON.parse(payload)
    rows_from_json(value)
  rescue JSON::ParserError
    nil
  end

  def rows_from_json(value)
    case value
    when Array
      rows_from_array(value)
    when Hash
      rows_from_hash(value)
    end
  end

  def rows_from_array(value)
    return if value.empty?

    if value.all? { |item| item.is_a?(Hash) }
      headers = value.flat_map(&:keys).uniq.map(&:to_s)
      rows = value.map { |item| headers.map { |header| json_cell(item[header]) } }
      return { headers: headers, rows: rows }
    end

    if value.all? { |item| item.is_a?(Array) }
      width = value.map(&:length).max
      headers = Array.new(width) { |idx| "Columna #{idx + 1}" }
      rows = value.map { |row| row.map { |cell| json_cell(cell) } }
      return { headers: headers, rows: rows }
    end

    { headers: ['Valor'], rows: value.map { |item| [json_cell(item)] } }
  end

  def rows_from_hash(value)
    headers = value.keys.map(&:to_s)
    return if headers.empty?

    {
      headers: headers,
      rows: [headers.map { |header| json_cell(value[header]) }]
    }
  end

  def json_cell(value)
    return '' if value.nil?
    return value.to_s unless value.is_a?(Array) || value.is_a?(Hash)

    JSON.generate(value)
  end

  def usable_table?(header, rows)
    return false if header.empty? || header.all?(&:empty?)
    return false if rows.empty?

    rows.any? { |row| row.any? { |cell| !cell.empty? } }
  end

  def table_row?(line)
    line.to_s.strip.include?('|')
  end

  def separator_row?(line)
    cells = parse_row(line)

    cells.length > 1 && cells.all? { |cell| cell.match?(/\A:?-{3,}:?\z/) }
  end

  def parse_row(line)
    stripped = line.to_s.strip
    stripped = stripped.delete_prefix('|')
    stripped = stripped.delete_suffix('|')
    stripped.split('|').map(&:strip)
  end
end
