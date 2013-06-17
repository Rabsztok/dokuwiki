#!/usr/bin/env ruby

require_relative 'scanner.rb'
puts Scanner.new(ARGF).run
