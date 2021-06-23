#!/usr/bin/env ruby

# require 'pathname'
# require File.dirname(__FILE__)+'/filemessage.pb.rb'
require 'victoriafresh'
require 'cbor'
require 'lzma'
require 'get_process_mem'

def checkMemoryUsage(lineNumber)
            mem= GetProcessMem.new
    
    puts("#{lineNumber} ,  Memory: #{mem.mb}"); #Debug

end #def checkMemoryUsage

#根据版本号，提取VFS数据内容
def extractVfsDataWithVersionExternalFile(wholeCbor, fileVersion) 
    victoriaFreshData='' #解压后的数据块整体
    dataFileName='victoriafreshdata.w' #数据文件名
    dataFile={} #数据文件对象
    
    if (fileVersion==14) #14版本
        compressedVfsData=wholeCbor['vfsData'] #获取压缩后的数据内容
        
        victoriaFreshData=LZMA.decompress(compressedVfsData) #解压缩数据内容
        
        dataFile=File.open(dataFileName, 'wb') #打开文件
        
        dataFile.syswrite(victoriaFreshData) #写入内容
        
        dataFile.close #关闭文件
    elsif (fileVersion>=30) #30以上版本
        compressedVfsDataList=wholeCbor['vfsDataList'] #获取压缩后的数据块列表
        
        puts("data block amont: #{compressedVfsDataList.length}") #Debug
        
        dataBlockCounter=0 #Data block counter
        
        dataFile=File.open(dataFileName, 'wb') #打开文件

        
        compressedVfsDataList.each do |currentCompressed| #一块块地解压
            puts("data block counter: #{dataBlockCounter}") #Debug
            checkMemoryUsage(34)

            currentRawData=LZMA.decompress(currentCompressed) #解压这一块

            dataFile.syswrite(currentRawData) #写入内容

#             victoriaFreshData=victoriaFreshData+currentRawData #追加
#             victoriaFreshData << currentRawData #追加

            puts("byte size: #{victoriaFreshData.bytesize}") #debug.
            
            dataBlockCounter=dataBlockCounter+1 #count
        end #compressedVfsDataList.each do |currentCompressed|
        
        dataFile.close #关闭文件
    end #if (fileVersion==14) #14版本
    
    return dataFileName #返回解压后的数据块整体
end #def extractVfsDataWithVersionExternalFile(wholeCbor, fileVersion) #根据版本号，提取VFS数据内容

def extractVfsDataWithVersion(wholeCbor, fileVersion) #根据版本号，提取VFS数据内容
    victoriaFreshData='' #解压后的数据块整体
    
    if (fileVersion==14) #14版本
        compressedVfsData=wholeCbor['vfsData'] #获取压缩后的数据内容
        
        victoriaFreshData=LZMA.decompress(compressedVfsData) #解压缩数据内容
    elsif (fileVersion>=30) #30以上版本
        compressedVfsDataList=wholeCbor['vfsDataList'] #获取压缩后的数据块列表
        
        puts("data block amont: #{compressedVfsDataList.length}") #Debug
        
        dataBlockCounter=0 #Data block counter
        
        compressedVfsDataList.each do |currentCompressed| #一块块地解压
            puts("data block counter: #{dataBlockCounter}") #Debug
            checkMemoryUsage(34)

            currentRawData=LZMA.decompress(currentCompressed) #解压这一块

#             victoriaFreshData=victoriaFreshData+currentRawData #追加
            victoriaFreshData << currentRawData #追加

            puts("byte size: #{victoriaFreshData.bytesize}") #debug.
            
            dataBlockCounter=dataBlockCounter+1 #count
        end #compressedVfsDataList.each do |currentCompressed|
    end #if (fileVersion==14) #14版本
    
    return victoriaFreshData #返回解压后的数据块整体
end #        extractVfsDataWithVersion(wholeCbor, fileVersion) #根据版本号，提取VFS数据内容

class ExtremeUnZip
    #解压
    def exuz(rootPath)
        wholeFileContent=File.read(rootPath) #最终文件内容
        
        checkMemoryUsage(60)
        
        puts wholeFileContent.class #debug
        
        wholeCborByteArray=wholeFileContent[4..-1] #从第5个到末尾
        checkMemoryUsage(65)
        
        
        #     puts wholeCborByteArray #Debug.
        
        checkMemoryUsage(70)
        wholeCbor=CBOR.decode(wholeCborByteArray) #解码
        #     wholeCbor=wholeCborByteArray.from_cbor #解码CBOR
        
        #     puts wholeCbor #Debug.
        checkMemoryUsage(75)
        
        fileVersion=wholeCbor['version'] #获取版本号
        
        puts 'fileVersion:' #Debug
        checkMemoryUsage(80)
        puts fileVersion #Debug.
        
        
        if (fileVersion<14) #版本号过小
            checkMemoryUsage(85)
            puts 'file version too old' #报告错误
        else #版本号够大
            compressedVfsMenu=wholeCbor['vfsMenu'] #获取压缩后的目录内容
            
            checkMemoryUsage(90)
            replyByteArray=LZMA.decompress(compressedVfsMenu) #解码目录VFS字节数组内容
            
            #         puts replyByteArray #Debug
            
            checkMemoryUsage(95)
            #         victoriaFreshData=extractVfsDataWithVersion(wholeCbor, fileVersion) #根据版本号，提取VFS数据内容
            victoriaFreshDataFile=extractVfsDataWithVersionExternalFile(wholeCbor, fileVersion) #根据版本号，提取VFS数据内容
            
            #         puts victoriaFreshData #Debug
            
            checkMemoryUsage(100)
            $clipDownloader=VictoriaFresh.new #创建下载器。
            
            
            $clipDownloader.releaseFilesExternalDataFile(replyByteArray, victoriaFreshDataFile) #释放各个文件
            
            fileToRemove=File.new(victoriaFreshDataFile) #要删除的文件
            
            File.delete(fileToRemove) #删除文件
            
        end #if (fileVersion<14) #版本号过小
        
    end #def exuz(rootPath)
end #class ExtremeUnZip

