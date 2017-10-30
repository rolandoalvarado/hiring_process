#!/usr/bin/env ruby

require_relative 'processor'

puts 'This script will read a text file input.txt as input where each line is a special command,'
puts 'and write responses to another file output.txt'
puts 'USAGE: PROCESS [INPUT_TEXTFILE] OR PROCESS [INPUT_TEXTFILE] [OUTPUT_TEXTFILE]'
puts 'Enter command and text filename to process.'


if ARGV.length > 0
  file_path = "/../#{ARGV[0]}"
  puts File.read(File.dirname(__FILE__) + file_path)
  puts "Take note command is case sensitive."
end

processor = Processor.new

command = STDIN.gets

while command
  output = processor.execute(command)
  puts output if output
  command = STDIN.gets
end
