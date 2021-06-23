#!/usr/bin/env ruby

thr = Thread.new { puts "Whats the big deal" }
thr.join
