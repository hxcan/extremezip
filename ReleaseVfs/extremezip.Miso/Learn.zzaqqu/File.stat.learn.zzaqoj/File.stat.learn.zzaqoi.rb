#!/usr/bin/env ruby

Dir["**/**"].each do |f| 
    printf "%04o\t#{f}\n", File.stat(f).mode & 07777 
    puts(File.stat(f).mode & 07777)
end
