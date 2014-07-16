#!/usr/bin/env python
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

import sys, pty, tty, signal, os;

signal.signal(signal.SIGINT, signal.SIG_DFL)

status = pty.spawn(sys.argv[1:])

# Some versions of python don't return the exit status (e.g. 2.x)
if status == None:
	status = os.wait()[1]

exit_code = os.WEXITSTATUS(status)
exit_signal = os.WTERMSIG(status)

# Cause the wrapper process to die in the same way, so that the status is propagated upstream:
if exit_signal != 0:
	os.kill(os.getpid(), exit_signal)
else:
	sys.exit(exit_code)
