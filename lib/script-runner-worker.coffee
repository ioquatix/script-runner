Shellwords = require('shellwords')
PTY = require('pty.js')

# This is the shim which runs the actual process. We need to do this so the tty interface can be emulated correctly.
process.on 'message', (msg) ->
  if msg.action == 'run'
    cmd = Shellwords.split(msg.cmd)
    term = PTY.spawn cmd[0], cmd.slice(1),
      name: 'xterm-color',
      cols: 80,
      rows: 40,
      cwd: msg.cwd,
      env: process.env
    
    term.on 'data', (data) -> process.stdout.write(data)
    
    process.on 'SIGCHLD', ->
      process.exit(0)
