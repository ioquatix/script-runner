#!/usr/bin/env coffee

console.log(process.env)

ChildProcess = require 'child_process'

# This command should generate a list of all exports from a login shell:
exportsCommand = process.env.SHELL + " -lc export"

# Run the command and update the local process environment:
ChildProcess.exec exportsCommand, (error, stdout, stderr) ->
	for definition in stdout.trim().split('\n')
		[key, value] = definition.split('=', 2)
		process.env[key] = value