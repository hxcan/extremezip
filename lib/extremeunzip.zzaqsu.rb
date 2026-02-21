require 'victoriafresh'
require 'cbor'
require 'lzma'
require 'get_process_mem'


def checkMemoryUsage(lineNumber)
  mem = GetProcessMem.new
  puts("#{lineNumber} ,  Memory: #{mem.mb}") # Debug
end

class ExtremeUnZip
  def initialize
    # 移除 StreamDecoder 初始化，改为直接调用 LZMA.decompress
  end

  def readVfsDataList(wholeCbor, currentBlockFile) 
    compressedVfsDataList = []
    startIndix = wholeCbor['vfsDataListStart']

    puts "list content: #{wholeCbor['vfsDataList']}" # Debug
    
    expected_block_length = nil

    # ✅ Release @wholeFileContent BEFORE the loop
    @wholeFileContent = nil
    GC.start

    # Ensure temp dir exists
    Dir.mkdir('/tmp/exz_blocks') rescue Errno::EEXIST

    wholeCbor['vfsDataList'].each_with_index do |currentBlockInfo, index|
      length = currentBlockInfo['length']
      
      if expected_block_length.nil?
        expected_block_length = length
      elsif length != expected_block_length
        puts "Warning: unexpected block length detected. Expected: #{expected_block_length}, got: #{length}"
      end
      
      # ✅ Read directly from file on disk
      currentBlockFile.seek(startIndix)
      currentBlock = currentBlockFile.read(length)
      
      # ✅ Write to persistent temp file (not Tempfile)
      path = "/tmp/exz_blocks/block_#{Time.now.to_i}_#{rand(1000..9999)}.dat"
      File.open(path, 'wb') do |f|
        f.binmode
        f.write(currentBlock)
      end
      
      # Store path only
      compressedVfsDataList << path
      
      # ✅ Immediately release currentBlock
      currentBlock = nil
      
      # Optional: trigger GC periodically
      GC.start if index % 5 == 0

      startIndix += length

      # ✅ Monitor memory after each block
      checkMemoryUsage(200)
    end

    compressedVfsDataList
  end
  
  def extractVfsDataWithVersionExternalFile(wholeCbor, fileVersion, currentBlockFile)
    dataFileName = 'victoriafreshdata.w'
    expected_block_length = nil

    if (fileVersion == 14)
        compressedVfsData = wholeCbor['vfsData']
        victoriaFreshData = LZMA.decompress(compressedVfsData)


        File.open(dataFileName, 'wb') do |dataFile|
            dataFile.syswrite(victoriaFreshData)
            puts "After writing initial block, raw data file size: #{File.size(dataFileName)}"
        end
    elsif (fileVersion >= 30)
        compressedVfsDataList = wholeCbor['vfsDataList']
        
        if (fileVersion >= 251)
          # Returns list of temp file paths
          compressedVfsDataList = readVfsDataList(wholeCbor, currentBlockFile)
        end 

        puts("data block amount: #{compressedVfsDataList.length}")

        dataBlockCounter = 0
        previous_block_length = nil

        File.open(dataFileName, 'wb') do |dataFile|
          begin
            # Process one block at a time
            compressedVfsDataList.each_with_index do |temp_path, index|
              puts("data block counter: #{dataBlockCounter}")
              checkMemoryUsage(30)

              currentRawData = nil

              begin
                File.open(temp_path, 'rb') do |f|
                  compressedData = f.read
                  currentRawData = LZMA.decompress(compressedData)
                end

                if previous_block_length.nil?
                  previous_block_length = currentRawData.length
                  expected_block_length ||= previous_block_length
                elsif currentRawData.length != previous_block_length || currentRawData.length == 0
                  if currentRawData.length == 0
                    puts "Warning: decompressed block length is zero at block #{index}. Generating fake data of expected length."
                    currentRawData = "\x00" * expected_block_length
                  else
                    puts "Warning: unexpected decompressed block length detected at block #{index}. Previous length: #{previous_block_length}, current length: #{currentRawData.length}"
                  end
                end
                
                dataFile.syswrite(currentRawData)
                puts "After writing block #{index}, raw data file size: #{File.size(dataFileName)}"
              rescue RuntimeError => e
                puts "Warning: the exz file may be incomplete at block #{index}. Error: #{e.message}"
                
                fake_data_block = "\x00" * expected_block_length
                dataFile.syswrite(fake_data_block)
                puts "After writing fake block #{index}, raw data file size: #{File.size(dataFileName)}"
                next
              ensure
                # ✅ Delete after use
                File.unlink(temp_path) rescue nil
              end

              dataBlockCounter += 1
              checkMemoryUsage(70)
            end
          end
        end
    end

    dataFileName
  end

  def exuz(rootPath)
    result = true

    begin
        currentBlockFile = File.new(rootPath, 'rb')
        @wholeFileContent = currentBlockFile.read

        checkMemoryUsage(60)

        wholeCborByteArray = @wholeFileContent[4..-1]

        options = {:tolerant => true}
        wholeCbor = CBOR.decode(wholeCborByteArray, options)
            
        # ✅ Release wholeCborByteArray immediately after use
        wholeCborByteArray = nil
        GC.start

        fileVersion = wholeCbor['version']
            
        if (fileVersion < 14)
            checkMemoryUsage(85)
            puts 'file version too old'
        else
            compressedVfsMenu = wholeCbor['vfsMenu']
            puts "compressed vfs menu size: #{compressedVfsMenu.size}"

            checkMemoryUsage(90)
            replyByteArray = LZMA.decompress(compressedVfsMenu)
          
            checkMemoryUsage(95)

            # ✅ Pass currentBlockFile all the way down
            victoriaFreshDataFile = extractVfsDataWithVersionExternalFile(wholeCbor, fileVersion, currentBlockFile)
          
            checkMemoryUsage(100)
            $clipDownloader = VictoriaFresh.new
          
            $clipDownloader.releaseFilesExternalDataFile(replyByteArray, victoriaFreshDataFile)
          
            File.delete(victoriaFreshDataFile)
        end

        # ✅ Close file only after ALL operations
        currentBlockFile.close
        @wholeFileContent = nil

        result = true
    rescue EOFError => e
        puts "Error: the exz file may be incomplete. Error: #{e.message}"
        result = false
    rescue => e
        puts "Unexpected error: #{e.message}"
        result = false
    end
  end
end