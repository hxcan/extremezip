#!/usr/bin/env ruby

require 'cbor'
require 'lzma'
# decompressed = LZMA.decompress(File.read("compressed.lzma"))

vfsDataFile=File.open('/Data/SoftwareDevelop/extremezip/VfsConent/extremezip.Miso.exz.vfs.data', 'rb') #打开数据文件

# vfsDataFile.syswrite(vfsData0) #写入文件内容

vfsData0=vfsDataFile.read #全部读入

vfsDataRawContent=LZMA.decompress(vfsData0) #解压

vfsDataRaw=File.open('/Data/SoftwareDevelop/extremezip/VfsConent/extremezip.Miso.exz.vfs.data.raw', 'wb') #打开文件
vfsDataRaw.syswrite(vfsDataRawContent) #写入内容

vfsMenuDataFile=File.open('/Data/SoftwareDevelop/extremezip/VfsConent/extremezip.Miso.exz.vfs.menu', 'rb') #打开数据文件
vfsMenuData=vfsMenuDataFile.read #全部读入

vfsMenuDataRaw=LZMA.decompress(vfsMenuData) #解压
vfsMenuFile=File.open('/Data/SoftwareDevelop/extremezip/VfsConent/extremezip.Miso.exz.vfs.menu.raw', 'wb') #打开数据文件
vfsMenuFile.syswrite(vfsMenuDataRaw) #写入内容
