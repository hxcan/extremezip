#!/usr/bin/env ruby

require 'cod'

zeroDotOne=0.1

# rd, wr = IO.pipe
pipe = Cod.pipe

pipe.put ('dddd')

p1 = fork do
#     rd.close
    #子进程中 ，占用wr
    sleep zeroDotOne 
    puts zeroDotOne
    
    readContent=pipe.get #读取
    puts("read from sub process: #{readContent}") #Debug

    
#     wr.write("主进程中，占用rd：")
#     wr.close
    
    
    
#     pipe.put('主进程中，占用rd：')
#     pipe.put({'a' => 'b'})
end


p2 = fork { sleep 0.2 }
Process.detach(p1)
Process.waitpid(p2)
sleep 2

#主进程中，占用rd：
# wr.close
# readContent=rd.read #读取
# readContent=pipe.get #读取
puts readContent #Debug
# readContent=pipe.get #读取
puts readContent #Debug
# rd.close

system("ps -ho pid,state -p #{p1}")
