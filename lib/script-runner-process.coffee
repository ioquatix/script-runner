ChildProcess = require('child_process')
ChildPTY = require('child_pty')
Path = require('path')
Shellwords = require('shellwords')

module.exports =
class ScriptRunnerProcess
  @run: (view, cmd, env, editor) ->
    scriptRunnerProcess = new ScriptRunnerProcess(view)
    
    scriptRunnerProcess.execute(cmd, env, editor)
    
    return scriptRunnerProcess
  
  constructor: (view) ->
    @view = view
    @child = null
  
  detach: ->
    @view = null
  
  stop: (signal = 'SIGINT') ->
    if @child
      console.log("Sending", signal, "to child", @child, "pid", @child.pid)
      process.kill(-@child.pid, signal)
      if @view
        @view.append('<Sending ' + signal + '>', 'stdin')
  
  execute: (cmd, env, editor) ->
    cwd = atom.project.path
    
    # Split the incoming command so we can modify it
    args = Shellwords.split(cmd)
    
    # Save the file if it has been modified:
    if editor.getPath()
      editor.save()
      cwd = Path.dirname(editor.getPath())
    
    # If the editor refers to a buffer on disk which has not been modified, we can use it directly:
    if editor.getPath() and !editor.buffer.isModified()
      args.push(editor.getPath())
      appendBuffer = false
    else
      appendBuffer = true
    
    # Spawn the child process:
    @child = ChildPTY.spawn(args[0], args.slice(1), cwd: cwd, env: env)
    
    # Update the status (*Shellwords.join doesn't exist yet):
    @view.header('Running: ' + args.join(' ') + ' (pid ' + @child.pid + ')')
    
    # Handle various events relating to the child process:
    @child.pty.on 'data', (data) =>
      if @view?
        lines = data.toString().split '\n'
        for line in lines
          @view.append(line, 'stdout')
        
        @view.scrollToBottom()
    
    @child.on 'close', (code, signal) =>
      #console.log("process", args, "exit", code, signal)
      @child = null
      if @view
        duration = ' after ' + ((new Date - startTime) / 1000) + ' seconds'
        if signal
          @view.footer('Exited with signal ' + signal + duration)
        else
          # Sometimes code seems to be null too, not sure why, perhaps a bug in node.
          code ||= 0
          @view.footer('Exited with status ' + code + duration)
    
    startTime = new Date
    
    # Could not supply file name:
    if appendBuffer
      @child.stdin.write(editor.getText())
    
    @child.stdin.end()
