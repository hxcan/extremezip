#!/usr/bin/env ruby

puts Process.getpgid(Process.ppid())

puts Process.getpgrp

puts Process.getpriority(Process::PRIO_USER, 0)
puts Process.getpriority(Process::PRIO_PROCESS, 0)

puts Process.getsid()
puts Process.getsid(0)
puts Process.getsid(Process.pid())

puts Process.gid

puts Process.groups
