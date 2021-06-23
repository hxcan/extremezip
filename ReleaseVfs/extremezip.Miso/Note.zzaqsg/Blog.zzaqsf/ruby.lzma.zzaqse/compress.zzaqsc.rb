#!/usr/bin/env ruby

require 'lzma'

originalFileContent=File.read('manifestfulltextcache')

puts("Original file length: #{originalFileContent.bytesize}")

compressedContent=LZMA.compress(originalFileContent)

puts("Compressed content length: #{compressedContent.bytesize}")

compressedFile=File.new('manifestfulltextcache.compressed', 'wb')
compressedFile.syswrite(compressedContent)
compressedFile.close
