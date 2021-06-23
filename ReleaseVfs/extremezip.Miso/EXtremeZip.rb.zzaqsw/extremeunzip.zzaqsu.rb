#!/usr/bin/env ruby

# require 'pathname'
# require File.dirname(__FILE__)+'/filemessage.pb.rb'
require 'victoriafresh'
require 'cbor'
require 'lzma'

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
            puts("data block cmounter: #{dataBlockCounter}") #Debug
            
            currentRawData=LZMA.decompress(currentCompressed) #解压这一块

#             victoriaFreshData=victoriaFreshData+currentRawData #追加
            victoriaFreshData << currentRawData #追加

            
            puts("byte size: #{victoriaFreshData.bytesize}") #debug.
            
            dataBlockCounter=dataBlockCounter+1 #count


        end #compressedVfsDataList.each do |currentCompressed|
    end #if (fileVersion==14) #14版本
    
    return victoriaFreshData #返回解压后的数据块整体
end #        extractVfsDataWithVersion(wholeCbor, fileVersion) #根据版本号，提取VFS数据内容

if (ARGV.empty? ) #未指定命令行参数。
else #指定了命令行参数。
    $rootPath=ARGV[0] #记录要打包的目录树的根目录。
    
    
    wholeFileContent=File.read($rootPath) #最终文件内容
    
    #     puts wholeFileContent #Debug.
    
    puts wholeFileContent.class #debug
    
    wholeCborByteArray=wholeFileContent[4..-1] #从第5个到末尾
    
    
    #     puts wholeCborByteArray #Debug.
    
    wholeCbor=CBOR.decode(wholeCborByteArray) #解码
    #     wholeCbor=wholeCborByteArray.from_cbor #解码CBOR
    
    #     puts wholeCbor #Debug.
    
    fileVersion=wholeCbor['version'] #获取版本号
    
    puts 'fileVersion:' #Debug
    puts fileVersion #Debug.
    
    
    if (fileVersion<14) #版本号过小
        puts 'file version too old' #报告错误
    else #版本号够大
        compressedVfsMenu=wholeCbor['vfsMenu'] #获取压缩后的目录内容
        
        replyByteArray=LZMA.decompress(compressedVfsMenu) #解码目录VFS字节数组内容
        
        puts replyByteArray #Debug
        
        victoriaFreshData=extractVfsDataWithVersion(wholeCbor, fileVersion) #根据版本号，提取VFS数据内容
        
        #         puts victoriaFreshData #Debug
        
        $clipDownloader=VictoriaFresh.new #创建下载器。
        
        
        $clipDownloader.releaseFiles(replyByteArray, victoriaFreshData) #释放各个文件
        
    end #if (fileVersion<14) #版本号过小
    
end
# end
