#!/usr/bin/env ruby

require 'cbor'
require 'lzma'
# decompressed = LZMA.decompress(File.read("compressed.lzma"))

def releaseDirectory(vfsMenu) #释放目录
    subFiles=vfsMenu['sub_files'] #子文件列表
    
    subFiles.each do |currentFile|
        releaseEntry(currentFile) #释放
    end #subFiles.each do |currentFile|
end #releaseDirectory(vfsMenu) #释放目录

def releaseEntry(vfsMenu) #释放条目
    if (vfsMenu['is_file']) #是文件
        releaseFile(vfsMenu) #释放文件
    else #是目录
        releaseDirectory(vfsMenu) #释放目录
    end #else #是目录
end #def releaseEntry(vfsMenu) #释放条目

def releaseFile(vfsMenu) #释放一个具体文件
    name=vfsMenu['name'] #文件名
    length=vfsMenu['file_length'] #文件长度
    start_index=vfsMenu['file_start_index'] #文件起始位置
    puts("name: #{name}, length: #{length}, start index: #{start_index}") #Debug
    
    currentFile=File.open(name, 'wb') #打开文件
    fileContent=$vfsData0Raw[start_index.. (start_index+length)] #截取内容
    
    currentFile.syswrite(fileContent) #写入内容
end #def releaseFile(vfsMenu) #释放一个具体文件

vfsDataFileRaw=File.open('/Data/SoftwareDevelop/extremezip/VfsConent/extremezip.Miso.exz.vfs.data.raw', 'rb') #打开数据文件

$vfsData0Raw=vfsDataFileRaw.read #全部读入



vfsDataFile=File.open('/Data/SoftwareDevelop/extremezip/VfsConent/extremezip.Miso.exz.vfs.menu.raw', 'rb') #打开数据文件

vfsData0=vfsDataFile.read #全部读入



vfsMenu=CBOR.decode(vfsData0) #解码

# puts(vfsMenu) #Debug

vfsMenu.each do |name, value|
    puts ("name: #{name}") #Debug
    
    
end #vfsMenu.each do |name, value|

releaseEntry(vfsMenu) #释放条目

