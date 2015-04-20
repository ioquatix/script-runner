#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright, 2014, by Samuel Williams. <http://www.codeotaku.com>
# Released under the MIT license.
"""
This script tries it's best to wrap a child command in a PTY. Insert it before 
the command you want to run and it will run the command on a virtual PTY, and 
exit with identical status/signal codes.

I've tried lots of options, including:
	script -qfec $cmd /dev/null
		Not cross platform to Mac OS X (different arguments)
	unbuffer
		Works - requires additional instal of Tcl+Expect
	pty.js + child_process.fork()
		Working - no way to get exit status, build issues.

I wanted to avoid having additional dependencies, but I believe that this is the
best option. This script should be Python2.7/3.3 compatible (with a few minor
exceptions which are delt with below).
"""

import sys, pty, os, subprocess
from select import select

STDIN_FILENO = 0
STDOUT_FILENO = 1
STDERR_FILENO = 2

# signal.signal(signal.SIGINT, signal.SIG_DFL)

def debug(msg):
	sys.stderr.write(msg)
	sys.stderr.flush()

# Compatibility with python 2.7 which doesn't have FileNotFoundError.
try:
	FileNotFoundError
except NameError:
	FileNotFoundError = OSError

def write_all(fd, data):
	"""Write all the data to a descriptor."""
	while data:
		n = os.write(fd, data)
		data = data[n:]

class ScriptWrapper:
	def __init__(self, command = sys.argv[1:]):
		self.command = command
	
	def spawn(self):
		self.master, slave = pty.openpty()
		self.child = subprocess.Popen(self.command, stdout=slave, stderr=slave, close_fds=True)
		os.close(slave)
		
		return self.wait_for_completion()

	def wait_for_completion(self):
		status = None
		
		while True:
			rlist, wlist, xlist = select([self.master], [], [])
			
			if rlist:
				try:
					data = os.read(self.master, 1024)
					
					# Mac OS X:
					if len(data) == 0:
						break
					
					write_all(STDOUT_FILENO, data)
				except OSError:
					# Linux, all data consumed:
					break
		
		# Process status not reaped yet, all input was consumed:
		return self.child.wait()

status = 1

wrapper = ScriptWrapper()

try:
	status = wrapper.spawn()
except FileNotFoundError as error:
	# Usually occurs if the shebang line executable was incorrect/unavailable:
	debug("%s while trying to execute %s" % (error, wrapper.command[0]))

# Cause the wrapper process to die in the same way, so that the status is propagated upstream:
if status < 0:
	os.kill(os.getpid(), -status)
else:
	sys.exit(status)
