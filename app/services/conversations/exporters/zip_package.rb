# frozen_string_literal: true

require 'zlib'

# Pure Ruby ZIP packager used by exporters that produce OOXML / ODF documents
# (which are ZIP containers with XML payloads). Avoids adding external
# dependencies for these formats.
class Conversations::Exporters::ZipPackage
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
