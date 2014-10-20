#!/usr/bin/env ruby

system("./test.rb")

Signal.trap("SIGINT") do
	puts "Interrupted"
end

system("./test.rb")

Signal.trap('SIGINT', 'SIG_IGN')

system("./test.rb")
