#!/usr/bin/env ruby

p Process.clock_getres(Process::CLOCK_MONOTONIC)

p Process.clock_gettime(Process::CLOCK_MONOTONIC)

p1 = fork { sleep 0.1 }
p2 = fork { sleep 0.2 }

Process.waitpid(p2)

sleep 2

system("ps -ho pid,state -p #{p1}")
