#!/usr/bin/ruby
# frozen_string_literal: true

require 'victoriafresh'
require 'cbor' # CBOR
require 'lzma' # LZMA
require 'etc' # cpu amount
require 'cod'
require 'uuid'
require 'get_process_mem'
require 'pathname'

def checkMemoryUsage(lineNumber)
  mem = GetProcessMem.new

  puts("#{lineNumber} ,  Memory: #{mem.mb}, process id: #{Process.pid}"); # Debug
end # def checkMemoryUsage

class ExtremeZip
  def initialize
    @wholeCbor = {} # 整个CBOR结构
    @vfsDataList = [] # 数据块压缩块列表
    @filePartCounter = 0 # 文件分块计数器
    @responsePipeList = [] # 任务回复管道列表
    @processIdList = [] # 子进程编号列表。
    @processTimestamp = Time.new.to_i # 记录进程启动的时间戳。
    @topFileList=[] # top file list. by length.
    @maxSubProcessAmount = Etc.nprocessors # 获取最大的子进程个数
    @leastTopFileLength=-4 # least top file length
    @dataBlockLength = 33554432 # 数据块单元长度， 32MiB

    @clipDownloader = VictoriaFresh.new # 创建下载器。

    @clipDownloader.diskFlush = true # 向磁盘写入缓存
    @clipDownloader.diskMultiFile = true # 写多个磁盘文件
    @clipDownloader.diskFileName = 'victoriafreshdata.v.' # 磁盘文件名前缀
    @clipDownloader.diskFlushSize = @dataBlockLength # 磁盘文件大小
    @clipDownloader.ignoreFileName= '.exzignore' # 设置用于指定忽略文件列表的文件名。
  end # def initialize
  
  # report top large file list.
  def reportTopLargeFileList(victoriaFresh) 
    #puts "vfs menu content: #{victoriaFresh}"
    puts "vfs menu class: #{victoriaFresh.class}"
    
    reportRememberOneFileNode(victoriaFresh, '.') # process one file node
    
    puts("Top large files:")
    
    @topFileList.each do |topFile|
      puts("#{topFile['name']}, #{topFile['parent_path']}, #{topFile['file_length']}")
    end 
  end # def reportTopLargeFileList(victoriaFresh) # report top large file list.
  
  # process one file node
  def reportRememberOneFileNode(victoriaFresh, parentPath) 
    if (victoriaFresh['is_file']) # it is a file
      file_lenght=victoriaFresh['file_length'] # get file length
      
      if  (file_lenght > (@leastTopFileLength) ) # larger than least top file length
        insertedFileObject=false
        if (@topFileList.size>=10) # already have 10 files in top list
          @topFileList.pop # pop last one.
        end # if (@topFileList.size>=10) # already have 10 files in top list
        
        #puts("#{__LINE__}, parent path:  #{victoriaFresh['parent_path']}")
        toInsertFileObject=victoriaFresh
        toInsertFileObject['parent_path']=parentPath
        #puts("#{__LINE__}, parent path:  #{toInsertFileObject['parent_path']},  #{victoriaFresh['parent_path']}")
        topFileIndex=0
        #if (@topFileList.size==0) # no item in list
          #puts("#{__LINE__}, insert, #{toInsertFileObject['name']}, #{toInsertFileObject['file_length']}")
          #@topFileList.insert(topFileIndex, toInsertFileObject) # insert into top file list.
        #else # if (@topFileList.size==0) # no item in list
          #topFileIndex=@topFileList.size - 1 
          
          fileIndexRange=0..(@topFileList.size-1)
          fileIndexRange.each do |topFileIndex|
          #while (topFileIndex>=0) do # find insert point one by one
            currentTopFile=@topFileList[topFileIndex]
            
            if (file_lenght>currentTopFile['file_length'])
              #puts("#{__LINE__}, insert, #{toInsertFileObject['name']}, #{toInsertFileObject['file_length']}, #{parentPath}, #{toInsertFileObject['parent_path']}")
              @topFileList.insert(topFileIndex, toInsertFileObject) # insert into top file list.
              insertedFileObject=true
              break
            end 
            
            #topFileIndex -= 1
          end # while (topFileIndex>=0) do # find insert point one by one
        #end # if (@topFileList.size==0) # no item in list
          
          unless insertedFileObject # not inserted file object
            @topFileList << (toInsertFileObject) # insert into top file list.
          end # unless insertedFileObject # not inserted file object
        
        @leastTopFileLength=@topFileList.last['file_length']
      end # if (file_lenght>leastTopFileLength) # larger than least top file length
    else # it is a directory
      puts "victoriaFresh: #{victoriaFresh}" # debug.
      victoriaFresh['sub_files']&.each do |sub_file| # remember sub files one by one. This might be a symbol link. 
        reportRememberOneFileNode(sub_file, "#{parentPath}/#{victoriaFresh['name']}")
      end # victoriaFresh['sub_files']&.each do |sub_file| # remember sub files one by one. This might be a symbol link. 
    end # else # it is a directory
  end # reportRememberOneFileNode(victoriaFresh) # process one file node

  # 压缩目录数据。
  def compressVfsMenu(victoriaFresh)
    replyByteArray = victoriaFresh.to_cbor # #打包成字节数组。

    # 压缩目录数据并放入CBOR：
    compressedVfsMenu = LZMA.compress(replyByteArray) # 压缩目录数据

    @wholeCbor['vfsMenu'] = compressedVfsMenu # 加入目录
  end # compressVfsMenu(victoriaFresh) # 压缩目录数据。

  # 加入基本文件信息
  def addBasicFileInformation
    @wholeCbor['version'] = 251 # 文件格式版本号

    uuid = UUID.new # 获取生成器
    @wholeCbor['uuid'] = uuid.generate # 指定本个压缩包的唯一编号
        
    @wholeCbor['website']='https://rubygems.org/gems/EXtremeZip' # 加入网站地址
        
    @wholeCbor['vfsDataListStart']=198910 # 压缩 VFS 数据列表起始位置。
  end # addBasicFileInformation # 加入基本文件信息
    
  def writeStamp(rootPath) # 更新时间戳文件
    directoryPathName=Pathname.new(rootPath) #构造路径名字对象。
    datastore=  "#{directoryPathName.expand_path}/.exzstamp"  # 配置文件路径
    puts "writing stamp file: #{datastore}" # Debug
      
    #stamp = wholeCbor['timestamp'] # 获取时间戳
    stampCbor={} # 时间戳对象。
    stampCbor['timestamp']= @processTimestamp # 设置时间戳。
      
    compressed= stampCbor.to_cbor  
      
      extremeZipOutputFile = File.new(datastore, 'wb') # 创建文件
      extremeZipOutputFile.syswrite(compressed) # 写入文件
      extremeZipOutputFile.close # 关闭文件
      
    end # writeStamp # 更新时间戳文件
    
    def loadStamp(rootPath) # 读取时间戳阈值。
      stamp=0 # 默认值。
      fileExists=false # 文件是否存在
      
      directoryPathName=Pathname.new(rootPath) #构造路径名字对象。
        
      isFile=directoryPathName.file? #是否是文件。

      unless isFile #是文件就跳过。 
        #陈欣
        
        datastore=  "#{directoryPathName.expand_path}/.exzstamp"  # 配置文件路径
        puts "reading stamp file: #{datastore}" # Debug
        
        begin # 尝试读取。
          
          #陈欣
          
          currentBlockFile = File.new(datastore, 'rb') # 打开文件
          
          fileExists=true # 文件存在

          stampFileContent = currentBlockFile.read # 读取全部内容

          currentBlockFile.close # 关闭文件
          
          options = {:tolerant => true}

          wholeCbor = CBOR.decode(stampFileContent, options) # 解码
          
          puts wholeCbor # Debug
          puts wholeCbor.inspect # Debug
            
          stamp = wholeCbor['timestamp'].to_i # 获取时间戳
          #stamp = wholeCbor.try(:[], 'timestamp') # 获取时间戳
          
          
        rescue Errno::ENOENT, TypeError

        end

        
      end #unless isFile #是文件就跳过。 
      
      return stamp, fileExists # 返回时间戳。
    end #loadStamp(rootPath) # 读取时间戳阈值。

    # 压缩
    def exz(rootPath)
      timestampTHreshold, fileExists=loadStamp(rootPath) # 读取时间戳阈值。
      
      puts "threshold: #{timestampTHreshold}" # Debug
      
      #陈欣
      
      if (timestampTHreshold > 0) # 有效的时间戳
        @clipDownloader.timestampThreshold=timestampTHreshold # 设置文件时间戳阈值。
      end #if (timestampTHreshold > 0) # 有效的时间戳

      puts "threshold vfs: #{@clipDownloader.timestampThreshold}" # Debug
      
      if fileExists # 存在文件，则表明将要发生增量压缩
        @wholeCbor['incremental']=true # 是增量压缩。
        
      end # if fileExists # 存在文件，则表明用户要求增量压缩

      @wholeCbor['timestamp']=@processTimestamp # 记录进程启动的时间戳。
      
      victoriaFresh, = @clipDownloader.checkOnce(rootPath) # 打包该目录树。

      @filePartAmount = @clipDownloader.currentDiskFlushSuffix # 获取文件个数

      compressVfsMenu(victoriaFresh) # 压缩目录数据。

      addBasicFileInformation # 加入基本文件信息

      processIdList, responsePipeList = launchSubProcesses # 启动子进程。
      
      reportTopLargeFileList(victoriaFresh) # report top large file list.

      receiveCompressedVfsDataList(processIdList, responsePipeList) # 接收压缩后的数据块列表

      checkMemoryUsage(155)
      @wholeCbor['vfsDataList'] = @vfsDataList # 加入数据

      wholeFileContent = 'exz' + "\0" + @wholeCbor.to_cbor # 追加CBOR字节数组
        
      vfsDataListStart=wholeFileContent.length # 按照现在的序列化情况，计算出来的起始位置。
        
      while (vfsDataListStart!=@wholeCbor['vfsDataListStart']) # 计算出的偏移不一致
        @wholeCbor['vfsDataListStart']=vfsDataListStart # 使用新的值
        wholeFileContent = 'exz' + "\0" + @wholeCbor.to_cbor # 追加CBOR字节数组
        vfsDataListStart=wholeFileContent.length # 按照现在的序列化情况，计算出来的起始位置。          
      end

      # 写入文件：
      writeFile(wholeFileContent, victoriaFresh) # 写入文件内容
        
      appendVfsDataList victoriaFresh # 追加压缩块列表数据。
      
      if fileExists # 存在文件，则表明将要发生增量压缩
        writeStamp (rootPath) # 更新时间戳文件
      end # if fileExists # 存在文件，则表明用户要求增量压缩
    end # def exz(rootPath)
    
    # 写入压缩块文件
    def writeCompressBlock(compressed, processCounter) 
      extremeZipOutputFile = File.new("comressed.#{processCounter}.cex", 'wb') # 创建文件
      extremeZipOutputFile.syswrite(compressed) # 写入文件
      extremeZipOutputFile.close # 关闭文件
    end
    
    # 追加压缩块列表数据。
    def appendVfsDataList (victoriaFresh)
      extremeZipOutputFile = File.new("#{victoriaFresh['name']}.exz", 'ab') # 打开文件
        
      processCounter=0 # 块计数器。
        
      @wholeCbor['vfsDataList'].each do
        #extremeZipOutputFile = File.new("comressed.#{processCounter}.cex", 'wb') # 创建文件

        currentBlockFile = File.new("comressed.#{processCounter}.cex", 'rb') # 打开文件

        wholeFileContent = currentBlockFile.read # 读取全部内容

        currentBlockFile.close # 关闭文件
        File.delete(currentBlockFile) # 删除数据块文件

          #wholeFileContent=File.read("comressed.#{processCounter}.cex", 'rb') # 读取压缩块。
          
        #puts "wirte file contetn length: #{wholeFileContent.length}" # Debghu
          
        extremeZipOutputFile.syswrite(wholeFileContent) # 写入文件
          
        processCounter += 1 # 计数
      end
        
      extremeZipOutputFile.close # 关闭文件
    end

    # 写入文件内容
    def writeFile(wholeFileContent, victoriaFresh)
      extremeZipOutputFile = File.new("#{victoriaFresh['name']}.exz", 'wb') # 创建文件
      extremeZipOutputFile.syswrite(wholeFileContent) # 写入文件
      extremeZipOutputFile.close # 关闭文件
    end # writeFile(wholeFileContent, victoriaFresh) #写入文件内容

    # 接收压缩后的数据块列表
    def receiveCompressedVfsDataList(processIdList, responsePipeList)
      processCounter = 0 # 子进程计数器
        
      while (processCounter<@filePartAmount) # 并不是所有分块都被处理完毕了。
        currentSubProcess=processIdList[processCounter] # 获取子进程对象

        compressed = receiveFromSubProcess(currentSubProcess, responsePipeList, processCounter) # 从子进程中读取数据，并终止子进程
          
        #写入当前压缩块到文件系统中去作为缓存。陈欣
        writeCompressBlock(compressed, processCounter) # 写入压缩块文件
          
        blockInfo={} # 块信息
        blockInfo['length']=compressed.length # 记录长度
          
        #puts "block length: #{blockInfo['length']}" # Debug

        @vfsDataList << blockInfo # 加入数据块列表中
        checkMemoryUsage(150)

        processCounter += 1 # 子进程计数
          
        if (@filePartCounter<@filePartAmount) # 还有一些分块尚未交给子进程进行处理
          schedule1Block(@filePartCounter) # 再启动一个子进程
        end # if (@filePartCounter<@filePartAmount) # 还有一些分块尚未交给子进程进行处理
      end # processIdList.each do |currentSubProcess|
    end # receiveCompressedVfsDataList # 接收压缩后的数据块列表

    # 读取块文件内容
    def readBlockFile(filePartCounter)
      currentBlockFile = File.new(@clipDownloader.diskFileName + filePartCounter.to_s + '.v', 'rb') # 打开文件

      currentBlockData = currentBlockFile.read # 读取全部内容

      currentBlockFile.close # 关闭文件

      File.delete(currentBlockFile) # 删除数据块文件

      currentBlockData
    end

    # 计划一个块的压缩计算
    def schedule1Block(filePartCounter)
      currentBlockData = readBlockFile(filePartCounter) # 读取块文件内容

      currentResponsePipe = Cod.pipe # 任务回复管道

      p1 = fork do # 复制出子进程
        compressInSubProcess(currentBlockData, currentResponsePipe) # 在子进程中具体执行的压缩代码
      end # p1 = fork do #复制出子进程

      # processDataLength += @dataBlockLength # 计数
      #checkMemoryUsage(130)

      # 记录管道：
      # taskPipeList << currentTaskPipe
      @responsePipeList << currentResponsePipe # 记录回复管道

      @processIdList << p1 # 记录到子进程列表中

      @filePartCounter += 1 # 计数

      [currentResponsePipe, p1]
    end # schedule1Block(filePartCounter) # 计划一个块的压缩计算

    # 启动子进程。
    def launchSubProcesses
      while ((@filePartCounter < @filePartAmount) && (@filePartCounter<@maxSubProcessAmount)) # 未处理完毕，并且未达到最大子进程个数
        currentResponsePipe, p1 = schedule1Block(@filePartCounter) # 计划一个块的压缩计算
      end # while processDataLength < victoriaFreshData.byte_size do #未处理完毕

      [@processIdList, @responsePipeList]
    end # launchSubProcesses # 启动子进程。

    # 在子进程中具体执行的压缩代码
    def compressInSubProcess(currentBlockData, currentResponsePipe)
      #checkMemoryUsage(115) # Debug
      currentBlockDataToCompress = currentBlockData # 读取数据块

      currentCompressedVfsData = LZMA.compress(currentBlockDataToCompress) # 压缩当前块

      #checkMemoryUsage(120)
      #puts("compressed data length: #{currentCompressedVfsData.bytesize}") # Debug.

      currentResponsePipe.put currentCompressedVfsData # 将压缩后的数据块写入到回复管道中

      puts("finished #{Process.pid}") # Debug
    end # compressInSubProcess(currentBlockData, currentResponsePipe)  # 在子进程中具体执行的压缩代码

    # 从子进程中读取数据，并终止子进程
    def receiveFromSubProcess(currentSubProcess, responsePipeList, processCounter)
      puts("waiting #{currentSubProcess}") # Debug
      #checkMemoryUsage(140)

      currentResponsePipe = responsePipeList[processCounter] # 任务回复管道

      currentCompressedVfsDataFromSubProcess = currentResponsePipe.get # 读取压缩后数据
      #checkMemoryUsage(145)

      Process.waitpid(currentSubProcess) # 等待该个子进程

        currentCompressedVfsDataFromSubProcess
    end # receiveFromSubProcess(currentSubProcess) # 从子进程中读取数据，并终止子进程
end # class ExtremeZip
