#!/usr/bin/env ruby

exzFile=File.open('/Data/SoftwareDevelop/extremezip/ManualUnzip/OrigianlFile/extremezip.Miso.exz', 'rb') #打开文件

whoelFileContent=exzFile.read #全部读取

puts whoelFileContent.length #Debug

contentWithOutHead=whoelFileContent[4..] #获取不带文件头的内容

cbOrFile=File.open('/Data/SoftwareDevelop/extremezip/ManualUnzip/RemoveHead/extremezip.Miso.exz.cbor', 'wb')

cbOrFile.syswrite(contentWithOutHead) #写入

cbOrFile.close #关闭文件
