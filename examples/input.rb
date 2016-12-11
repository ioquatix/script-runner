#!/usr/bin/env ruby

$stdout.write "Give me some love: "
input = $stdin.gets.chomp!

if input =~ /love/
	puts "Yeah baby!"
else
	puts "..."
end
