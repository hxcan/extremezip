#!/usr/bin/env ruby

p1 = fork { sleep 0.1 }
p2 = fork { sleep 0.2 }
Process.detach(p1)
Process.waitpid(p2)
sleep 2
system("ps -ho pid,state -p #{p1}")
