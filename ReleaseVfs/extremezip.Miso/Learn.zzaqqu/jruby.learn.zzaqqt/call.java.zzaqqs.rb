#!/usr/bin/env jruby

require 'java'

frame = javax.swing.JFrame.new
frame.getContentPane.add javax.swing.JLabel.new('Hello, World!')
frame.setDefaultCloseOperation javax.swing.JFrame::EXIT_ON_CLOSE
frame.pack
frame.set_visible true
