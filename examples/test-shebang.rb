#!/usr/bin/env ruby

puts ENV['PATH']
puts ENV['FOO']

puts Process.getsid

sleep 5

Process.kill('SIGKILL', 0)
