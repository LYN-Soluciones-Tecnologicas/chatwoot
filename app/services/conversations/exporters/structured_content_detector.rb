# frozen_string_literal: true

# Scans transcript messages for structured tabular content (Markdown tables)
# so the exporter can emit them as proper rows in CSV / XLSX. When no tables
# are detected the CSV / XLSX exporters fall back to a chronological dump of
# the messages, so this detector is purely informational — it never blocks
# the export.
class Conversations::Exporters::StructuredContentDetector
  PIPE_ROW = /\A\|.*\|\z/
  SEPARATOR_ROW = /\A\|[\s:|\-]+\|\z/

  def initialize(messages)
    @messages = messages
  end

  def tables
    @tables ||= @messages.flat_map { |message| extract_from(message) }
  end

  def structured?
    tables.any?
  end

  private

  def extract_from(message)
    content = message.content.to_s
    return [] if content.empty?

    lines = content.lines.map { |line| line.sub(/\r?\n\z/, '') }
    found = []
    index = 0

    while index < lines.length
      if pipe_row?(lines[index]) && index + 1 < lines.length && separator_row?(lines[index + 1])
        header = parse_row(lines[index])
        data_start = index + 2
        data_end = data_start
        data_end += 1 while data_end < lines.length && pipe_row?(lines[data_end])

        rows = lines[data_start...data_end].map { |line| parse_row(line) }
        if usable_table?(header, rows)
          found << {
            headers: header,
            rows: rows,
            sender: sender_for(message),
            message_id: message.id
          }
        end
        index = data_end
      else
        index += 1
      end
    end

    found
  end

  def usable_table?(header, rows)
    return false if header.empty? || header.all?(&:empty?)
    return false if rows.empty?

    rows.any? { |row| row.any? { |cell| !cell.empty? } }
  end

  def pipe_row?(line)
    stripped = line.to_s.strip
    return false unless stripped.match?(PIPE_ROW)

    stripped.count('|') >= 2
  end

  def separator_row?(line)
    line.to_s.strip.match?(SEPARATOR_ROW)
  end

  def parse_row(line)
    line.to_s.strip.gsub(/\A\||\|\z/, '').split('|').map(&:strip)
  end

  def sender_for(message)
    return 'yo' if message.incoming?

    message.sender&.try(:available_name).presence || message.sender&.try(:name).presence || 'Desconocido'
  end
end
