#!/usr/bin/env ruby

require 'set'
require 'rainbow'

puts Time.now.inspect

pid = ARGV[0] || $$

data = File.read("/proc/#{pid}/status") rescue ""

signals = {}

Signal.list.each do |signal, index|
	signals[index] = signal
end

ignored = Set.new

data.scan(/SigIgn:\s*(.*?)\n/) do |(mask)|
	flags = mask.to_i(16).to_s(2).split(//).reverse
	
	flags.each_with_index do |flag, index|
		#puts "Checking flag #{flag} for #{index}: #{signals[index+1]}"
		if flag == '1'
			ignored << signals[index+1]
		end
	end
end

puts Rainbow("Ignored: #{ignored.to_a.join(', ')}").red
