#!/usr/bin/env FOO="Hello World" ruby

puts ENV['FOO']

puts Process.getsid

sleep 5

Process.kill('SIGKILL', 0)
