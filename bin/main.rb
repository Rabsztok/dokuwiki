#!/usr/bin/env jruby

require_relative 'scanner.rb'
puts Scanner.new(ARGF).run
