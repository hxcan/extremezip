#!/usr/bin/env ruby

require 'victoriafresh'
require 'cbor'
require 'lzma'
require 'get_process_mem'

def checkMemoryUsage(lineNumber)
  mem = GetProcessMem.new

  puts("#{lineNumber} ,  Memory: #{mem.mb}"); # Debug
end # def checkMemoryUsage

class ExtremeUnZip
  # 根据偏移值来读取压缩块数据列表。
  def readVfsDataList(wholeCbor) 
    compressedVfsDataList = [] # 获取压缩后的数据块列表
    startIndix=wholeCbor['vfsDataListStart'] # 初始起始位置。
    
    puts "whole length: #{@wholeFileContent.length}, list conent: #{wholeCbor['vfsDataList']}" # Debug
    
    
    wholeCbor['vfsDataList'].each do |currentBlockInfo| # 一个个块地处理
      length=currentBlockInfo['length'] # 获取长度。
      
      currentBlock=@wholeFileContent[startIndix, length] # 读取内容
      
      compressedVfsDataList << currentBlock # 加入当前块
      
      startIndix+=length # 位移。
    end
    
    compressedVfsDataList # 返回 内容
  end
  
  # 根据版本号，提取VFS数据内容
  def extractVfsDataWithVersionExternalFile(wholeCbor, fileVersion)
    victoriaFreshData = '' # 解压后的数据块整体
    dataFileName = 'victoriafreshdata.w' # 数据文件名
    dataFile = {} # 数据文件对象

    if (fileVersion == 14) # 14版本
        compressedVfsData = wholeCbor['vfsData'] # 获取压缩后的数据内容

        victoriaFreshData = LZMA.decompress(compressedVfsData) # 解压缩数据内容

        dataFile = File.open(dataFileName, 'wb') # 打开文件

        dataFile.syswrite(victoriaFreshData) # 写入内容

        dataFile.close # 关闭文件
    elsif (fileVersion >= 30) # 30以上版本
        compressedVfsDataList = wholeCbor['vfsDataList'] # 获取压缩后的数据块列表
        
        if (fileVersion>=251) # 251 以上版本。要按照偏移值来读取压缩数据块列表。
          compressedVfsDataList=readVfsDataList(wholeCbor) # 根据偏移值来读取压缩块数据列表。
        end # if (fileVersion>=251) # 251 以上版本

        puts("data block amont: #{compressedVfsDataList.length}") # Debug

        dataBlockCounter = 0 # Data block counter

        dataFile = File.open(dataFileName, 'wb') # 打开文件

        compressedVfsDataList.each do |currentCompressed| # 一块块地解压
            puts("data block counter: #{dataBlockCounter}") # Debug
            checkMemoryUsage(34)

            begin # 解压
              currentRawData = LZMA.decompress(currentCompressed) # 解压这一块

              dataFile.syswrite(currentRawData) # 写入内容
            rescue RuntimeError => e # 解压失败
              puts "Warning: the exz file may be incomplete." # 报告错误。文件可能不完整。
            end # begin # 解压

            dataBlockCounter += 1 # count
        end # compressedVfsDataList.each do |currentCompressed|

        dataFile.close # 关闭文件
    end # if (fileVersion==14) #14版本

    dataFileName # 返回解压后的数据块整体
  end # def extractVfsDataWithVersionExternalFile(wholeCbor, fileVersion) #根据版本号，提取VFS数据内容

  # 解压
  def exuz(rootPath)
    result = true # 解压结果

    currentBlockFile = File.new(rootPath, 'rb') # 打开文件

    @wholeFileContent = currentBlockFile.read # 读取全部内容

    currentBlockFile.close # 关闭文件

    checkMemoryUsage(60)

    wholeCborByteArray = @wholeFileContent[4..-1] # 从第5个到末尾

    begin # 可能出错。
      options = {:tolerant => true}

      wholeCbor = CBOR.decode(wholeCborByteArray, options) # 解码
            
      fileVersion = wholeCbor['version'] # 获取版本号
            
      if (fileVersion < 14) # 版本号过小
        checkMemoryUsage(85)
        puts 'file version too old' # 报告错误
      else # 版本号够大
        compressedVfsMenu = wholeCbor['vfsMenu'] # 获取压缩后的目录内容
        puts "compressed vfs menu size: #{compressedVfsMenu.size}" # D3bug
                
        checkMemoryUsage(90)
        replyByteArray = LZMA.decompress(compressedVfsMenu) # 解码目录VFS字节数组内容
          
        checkMemoryUsage(95)

        victoriaFreshDataFile = extractVfsDataWithVersionExternalFile(wholeCbor, fileVersion) # 根据版本号，提取VFS数据内容
          
        checkMemoryUsage(100)
        $clipDownloader = VictoriaFresh.new # 创建下载器。
          
        $clipDownloader.releaseFilesExternalDataFile(replyByteArray, victoriaFreshDataFile) # 释放各个文件
          
        fileToRemove = File.new(victoriaFreshDataFile) # 要删除的文件
      end # if (fileVersion<14) #版本号过小
            
      result =true # 解压成功
    rescue EOFError => e # 文件内容提前到末尾。一般是压缩包文件未传输完全 。
      puts "Error: the exz file may be incomplete." # 报告错误。文件可能不完整。
            
      result = false # 失败
    end #begin # 可能出错。
  end # def exuz(rootPath)
end # class ExtremeUnZip
