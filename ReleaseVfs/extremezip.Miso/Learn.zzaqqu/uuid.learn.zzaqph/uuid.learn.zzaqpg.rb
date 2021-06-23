#!/usr/bin/env ruby

require 'uuid'

uuid = UUID.new
10.times do
    p uuid.generate
end
