#!/usr/bin/env ruby

require 'json'

newJson = ""

f = File.new('cards.json', 'r')
f.readlines.each do |line|
  newJson = line
end

cards = JSON.parse(newJson)

cards.keys.each do |key|
  puts key
end
