ChildProcess = require('child_process')
Path = require('path')
Shellwords = require('shellwords')

module.exports =
class ScriptRunnerProcess
  @run: (view, cmd, editor) ->
    scriptRunnerProcess = new ScriptRunnerProcess(view)
    
    scriptRunnerProcess.execute(cmd, editor)
    
    return scriptRunnerProcess
  
  constructor: (view) ->
    @view = view
    @child = null
  
  detach: ->
    @view = null
  
  stop: (signal = 'SIGINT') ->
    if @child
      #console.log("Sending", signal, "to child", @child, "pid", @child.pid)
      process.kill(-@child.pid, signal)
      if @view
        @view.append('<Sending ' + signal + '>', 'stdin')
  
  execute: (cmd, editor) ->
    cwd = atom.project.path

    # Save the file if it has been modified:
    if editor.getPath()
      editor.save()
      cwd = Path.dirname(editor.getPath())
    
    # If the editor refers to a buffer on disk which has not been modified, we can use it directly:
    if editor.getPath() and !editor.buffer.isModified()
      cmd = cmd + ' ' + editor.getPath()
      appendBuffer = false
    else
      cmd = cmd + ' ' + '/dev/stdin'
      appendBuffer = true
    
    # PTY emulation:
    #args = Shellwords.split(cmd)
    #args.unshift('unbuffer')
    args = ["script", "-qfec", cmd, "/dev/null"]
    #args = ["bash", "-c", cmd]
    
    #console.log("args", args, "cwd", cwd, process.pid)
    
    # Spawn the child process:
    @child = ChildProcess.spawn(args[0], args.slice(1), cwd: cwd, detached: true)
    
    # Handle various events relating to the child process:
    @child.stderr.on 'data', (data) =>
      if @view?
        @view.append(data, 'stderr')
        @view.scrollToBottom()
    
    @child.stdout.on 'data', (data) =>
      if @view?
        @view.append(data, 'stdout')
        @view.scrollToBottom()
    
    @child.on 'exit', (code, signal) =>
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
    
    @view.header('Running: ' + cmd + ' (pgid ' + @child.pid + ')')
