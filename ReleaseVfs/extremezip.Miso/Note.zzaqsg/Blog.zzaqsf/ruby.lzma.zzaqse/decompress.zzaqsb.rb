#!/usr/bin/env ruby

require 'lzma'

compressedContent=File.read('manifestfulltextcache.compressed')
puts("Compressed content length: #{compressedContent.bytesize}")

originalFileContent=LZMA.decompress(compressedContent)

puts("Decompressed file length: #{originalFileContent.bytesize}")

decompressedFile=File.new('manifestfulltextcache.decompressed', 'wb')
decompressedFile.syswrite(originalFileContent)
decompressedFile.close
