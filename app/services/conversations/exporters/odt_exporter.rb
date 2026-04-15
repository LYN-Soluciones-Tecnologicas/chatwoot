# frozen_string_literal: true

require 'cgi'
require 'zlib'

class Conversations::Exporters::OdtExporter < Conversations::Exporters::BaseExporter
  MIME_TYPE = 'application/vnd.oasis.opendocument.text'

  def render
    OdtPackage.new(
      'mimetype' => MIME_TYPE,
      'content.xml' => content_xml,
      'styles.xml' => styles_xml,
      'META-INF/manifest.xml' => manifest_xml
    ).render
  end

  private

  def content_xml
    rows = @messages.map { |message| row_xml(message) }.join("\n")

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
        xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
        xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
        xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" office:version="1.2">
        <office:automatic-styles>
          <style:style style:name="GeneratedAt" style:family="paragraph">
            <style:text-properties fo:font-size="11pt" fo:font-weight="bold" fo:color="#555555"/>
          </style:style>
          <style:style style:name="Sender" style:family="paragraph">
            <style:text-properties fo:font-size="11pt" fo:font-weight="bold"/>
          </style:style>
          <style:style style:name="Attachments" style:family="paragraph">
            <style:text-properties fo:font-size="10pt" fo:font-style="italic" fo:color="#555555"/>
          </style:style>
          <style:style style:name="Meta" style:family="paragraph">
            <style:text-properties fo:font-size="9pt" fo:color="#899096"/>
          </style:style>
        </office:automatic-styles>
        <office:body>
          <office:text>
            <text:h text:outline-level="1">#{xml_text(document_title)}</text:h>
            <text:p text:style-name="GeneratedAt">#{xml_text(generated_at)}</text:p>
            #{rows}
          </office:text>
        </office:body>
      </office:document-content>
    XML
  end

  def row_xml(message)
    attachments = attachment_names(message)
    attachment_text = attachments.any? ? "Adjuntos: #{attachments.join(', ')}" : nil

    [
      %(<text:p text:style-name="Sender">#{xml_text(sender_name(message))}</text:p>),
      message_text(message).present? ? "<text:p>#{xml_text(message_text(message))}</text:p>" : nil,
      attachment_text.present? ? %(<text:p text:style-name="Attachments">#{xml_text(attachment_text)}</text:p>) : nil,
      %(<text:p text:style-name="Meta">#{xml_text(formatted_timestamp(message))}</text:p>),
      '<text:p/>'
    ].compact.join("\n")
  end

  def styles_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <office:document-styles xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" office:version="1.2">
        <office:styles/>
      </office:document-styles>
    XML
  end

  def manifest_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.2">
        <manifest:file-entry manifest:media-type="#{MIME_TYPE}" manifest:full-path="/"/>
        <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="content.xml"/>
        <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="styles.xml"/>
      </manifest:manifest>
    XML
  end

  def xml_text(text)
    CGI.escapeHTML(text.to_s).gsub("\n", '<text:line-break/>')
  end

  class OdtPackage
    LOCAL_FILE_HEADER = 0x04034b50
    CENTRAL_DIRECTORY_HEADER = 0x02014b50
    END_OF_CENTRAL_DIRECTORY = 0x06054b50

    def initialize(entries)
      @entries = entries.map { |name, content| [name.to_s, content.to_s.dup.b] }
    end

    def render
      file_data = ''.b
      central_directory = ''.b

      @entries.each do |name, content|
        offset = file_data.bytesize
        file_data << local_file_header(name, content)
        file_data << content
        central_directory << central_directory_header(name, content, offset)
      end

      cd_offset = file_data.bytesize
      file_data << central_directory
      file_data << end_of_central_directory(central_directory, cd_offset)
      file_data
    end

    private

    def local_file_header(name, content)
      [
        LOCAL_FILE_HEADER, 20, 0, 0, 0, 0, checksum(content), content.bytesize, content.bytesize, name.bytesize, 0
      ].pack('VvvvvvVVVvv') + name
    end

    def central_directory_header(name, content, offset)
      [CENTRAL_DIRECTORY_HEADER, 20, 20, 0, 0, 0, 0, checksum(content), content.bytesize, content.bytesize,
       name.bytesize, 0, 0, 0, 0, 0, offset].pack('VvvvvvvVVVvvvvvVV') + name
    end

    def end_of_central_directory(central_directory, cd_offset)
      [
        END_OF_CENTRAL_DIRECTORY, 0, 0, @entries.size, @entries.size, central_directory.bytesize, cd_offset, 0
      ].pack('VvvvvVVv')
    end

    def checksum(content)
      Zlib.crc32(content)
    end
  end
end
