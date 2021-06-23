#!/usr/bin/env ruby

require 'cbor'

cbOrFile=File.open('/Data/SoftwareDevelop/extremezip/ManualUnzip/RemoveHead/extremezip.Miso.exz.cbor', 'rb')

cborObject=CBOR.decode(cbOrFile) #解析

puts cborObject

cborObject.each do |name, value|
    puts("name: #{name}") #Debug
    

end #cborObject.each do |name, value|

vfsMenuConent=cborObject['vfsMenu'] #菜单内容

vfsMenuFile=File.open('/Data/SoftwareDevelop/extremezip/VfsConent/extremezip.Miso.exz.vfs.menu', 'wb')
vfsMenuFile.syswrite(vfsMenuConent) #写入内容

puts("vfsDataList length: #{cborObject['vfsDataList'].length}") #Debug

vfsData0=cborObject['vfsDataList'][0] #第一段内容对象

puts("vfsData0: #{vfsData0}") #Debug
puts("vfsData0 length: #{vfsData0.length}") #Debug

vfsDataFile=File.open('/Data/SoftwareDevelop/extremezip/VfsConent/extremezip.Miso.exz.vfs.data', 'wb') #打开数据文件

vfsDataFile.syswrite(vfsData0) #写入文件内容
