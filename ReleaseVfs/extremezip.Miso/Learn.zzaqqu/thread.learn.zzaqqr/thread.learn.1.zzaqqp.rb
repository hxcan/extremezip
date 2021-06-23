#!/usr/bin/env ruby

threads = []
threads << Thread.new { puts "Whats the big deal" }
threads << Thread.new { 3.times { puts "Threads are fun!" } }
threads.each { |thr| thr.join }
