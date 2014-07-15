#!/usr/bin/env FOO="Hello World" ruby

puts ENV['FOO']

puts Process.getsid

# Process.kill('SIGKILL', -(Process.getpgrp - 2))