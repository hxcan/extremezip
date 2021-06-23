#!/usr/bin/ruby

require 'victoriafresh'
require 'cbor'
require 'lzma'
require 'etc' #cpu amount
require 'cod' 
require 'uuid'

if (ARGV.empty? ) #未指定命令行参数。
else #指定了命令行参数。
  $rootPath=ARGV[0] #记录要打包的目录树的根目录。
  
  $clipDownloader=VictoriaFresh.new #创建下载器。

  victoriaFresh,victoriaFreshData=$clipDownloader.checkOnce($rootPath) #打包该目录树。
  
  #利用protobuf打包成字节数组：
  replyByteArray="" #回复时使用的字节数组。
#   victoriaFresh.encode(replyByteArray) #打包成字节数组。
#   replyByteArray=Com::Stupidbeauty::Victoriafresh::FileMessage.encode(victoriaFresh) ##打包成字节数组。
  replyByteArray=victoriaFresh.to_cbor ##打包成字节数组。

  victoriaFreshFile=File.new("victoriafresh.v","wb") #创建文件。
  victoriaFreshFile.syswrite(replyByteArray) #写入文件。
  
  victoriaFreshFile.close #关闭文件。
  
  victoriaFreshDataFile=File.new("victoriafreshdata.v","wb") #数据文件。
  victoriaFreshDataFile.syswrite(victoriaFreshData) #写入文件。
  victoriaFreshDataFile.close #关闭文件。
  
  
  wholeFileContent='' #最终文件内容
  
  wholeFileContent = wholeFileContent + 'exz' + "\0" #写入魔法文件头
  
  wholeCbor={} #整个CBOR结构
  wholeCbor['version']=68 #文件格式版本号

  uuid = UUID.new #获取生成器
  generatedUuid=uuid.generate #生成唯一标识
  wholeCbor['uuid']=generatedUuid #指定本个压缩包的唯一编号
  
  #压缩目录数据并放入CBOR：
  compressedVfsMenu = LZMA.compress(replyByteArray) #压缩目录数据
  
  puts("compressed menu length: #{compressedVfsMenu.bytesize}") #Debug.
  wholeCbor['vfsMenu']=compressedVfsMenu #加入目录

  #压缩文件实体数据并放入CBOR：
#   dataBlockLength=16777216 #数据块单元长度， 16MiB
  dataBlockLength=33554432 #数据块单元长度， 32MiB
#   dataBlockLength=67108864 #数据块单元长度， 64MiB
  
  
  dynamicBlockLength=victoriaFreshData.bytesize / Etc.nprocessors + 1  #尝试根据现在的任务计算出一个动态块长度。
  
  
  
  maxAcceptableDataBlockLength=52852*1024 #Max acceptable data block length
  
  dataBlockLength=[dataBlockLength, dynamicBlockLength].max #取预定义的块长度和动态块长度中较大的那个来作为块长度。这样压缩比高一些
  
  dataBlockLength=[dataBlockLength, maxAcceptableDataBlockLength].min #Limit data block length, not to exceed max acceptable data block length.
  
  puts("block length: #{dataBlockLength}") #Debug
  
  
  processDataLength=0 #已处理的数据长度
  
  vfsDataList=[] #数据块压缩块列表
  taskPipeList=[] #任务分配管道列表。
  responsePipeList=[] #任务回复管道列表
  processIdList = [] #记录到子进程列表中
  
  while processDataLength < victoriaFreshData.bytesize do #未处理完毕
      currentBlockData=victoriaFreshData[processDataLength, dataBlockLength] #取出当前数据块
      
      currentTaskPipe=Cod.pipe #任务分配管道
      currentResponsePipe=Cod.pipe #任务回复管道
      
      #记录管道：
      taskPipeList << currentTaskPipe
      responsePipeList << currentResponsePipe

      p1 = fork do #复制出子进程
          currentBlockDataToCompress=currentBlockData #读取数据块
          
          currentCompressedVfsData=LZMA.compress(currentBlockDataToCompress) #压缩当前块
          
          puts("compressed data length: #{currentCompressedVfsData.bytesize}") #Debug.
          
          currentResponsePipe.put currentCompressedVfsData #将压缩后的数据块写入到回复管道中
          
          puts("finished #{Process.pid}") #Debug
      end #p1 = fork do #复制出子进程

      processDataLength=processDataLength + dataBlockLength #计数

      processIdList << p1 #记录到子进程列表中
  end #while processDataLength < victoriaFreshData.byte_size do #未处理完毕
  
  processCounter=0 #子进程计数器
  
  processIdList.each do |currentSubProcess|
      puts("waiting #{currentSubProcess}") #Debug
      
      currentResponsePipe=responsePipeList[processCounter] #任务回复管道
      
      currentCompressedVfsDataFromSubProcess=currentResponsePipe.get #读取压缩后数据
      
      Process.waitpid(currentSubProcess) #等待该个子进程
      
      vfsDataList << currentCompressedVfsDataFromSubProcess #加入数据块列表中
      
      processCounter=processCounter+1 #子进程计数
  end #processIdList.each do |currentSubProcess|
  
  wholeCbor['vfsDataList']=vfsDataList #加入数据
  
  #序列化CBOR：
  wholeCborByteArray=wholeCbor.to_cbor
  
  wholeFileContent = wholeFileContent + wholeCborByteArray
  
  #写入文件：
  extremeZipOutputFile=File.new( victoriaFresh['name'] + '.exz', 'wb') #创建文件
  extremeZipOutputFile.syswrite(wholeFileContent) #写入文件
  extremeZipOutputFile.close #关闭文件
end
