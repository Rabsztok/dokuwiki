#!/usr/bin/env jruby

require_relative 'scanner.rb'
require_relative 'parser.rb'

tokens = Scanner.new(ARGF).scan
puts "=====      TOKENY      ======"
puts tokens.inspect
puts "===== SPARSOWANY TEKST ======"
puts Parser.new.parse(tokens)
