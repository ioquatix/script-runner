ChildProcess = require('child_process')
PTY = require('node-pty')
OS = require('os')
Path = require('path')
Shellwords = require('shellwords')
TempWrite = require('temp-write')
Path = require('path');

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
  
  resolvePath: (editor, callback) ->
    if editor.getPath()
      cwd = Path.dirname(editor.getPath())
      
      # Save the file if it has been modified:
      editor.save()
      
      callback(editor.getPath(), cwd)
      
      return true
    
    # Otherwise it was not handled:
    return false
  
  resolveSelection: (editor, callback) ->
    if editor.getPath()
      cwd = Path.dirname(editor.getPath())
    else
      cwd = atom.project.path
    
    selection = editor.getLastSelection()
    
    if selection? and !selection.isEmpty()
      callback(selection.getText(), cwd)
      return true
    
    # Otherwise it was not handled:
    return false
  
  resolveBuffer: (editor, callback) ->
    if editor.getPath()
      cwd = Path.dirname(editor.getPath())
    else
      cwd = atom.project.path
    
    callback(editor.getText(), cwd)
    
    return true
  
  execute: (cmd, env, editor) ->
    # Split the incoming command so we can modify it
    args = Shellwords.split cmd
    
    return true if @resolveSelection editor, (text, cwd) =>
      args.push TempWrite.sync(text)
      @spawn args, cwd, env
    
    return true if @resolvePath editor, (path, cwd) =>
      args.push path
      @spawn args, cwd, env
    
    return true if @resolveBuffer editor, (text, cwd) =>
      args.push TempWrite.sync(text)
      @spawn args, cwd, env
    
    # something really has to go wrong for this.
    return false
  
  spawn: (args, cwd, env, callback) ->
    # Spawn the child process:
    console.log("ScriptRunner.spawn", args[0], args.slice(1), cwd, env)
    
    @pty = PTY.open()
    @child = ChildProcess.spawn(args[0], args.slice(1), cwd: cwd, env: env, stdio: [@pty.slave, @pty.slave, @pty.slave], detached: true)
    # @pty.slave.end()
    
    @startTime = new Date
    
    # Update the status (*Shellwords.join doesn't exist yet):
    @view.setHeader('Running: ' + args.join(' ') + ' (pgid ' + @child.pid + ')')
    
    @view.on 'data', (data) =>
      #console.log('view -> pty (data)', data.length)
      if @pty?
        @pty.master.write(data)
    
    @view.on 'resize', (geometry) =>
      #console.log('view -> pty (resize)', geometry)
      if @pty?
        @pty.resize(geometry.cols, geometry.rows)
    
    @view.focus()
    
    # Handle various events relating to the child process:
    @pty.master.on 'data', (data) =>
      #console.log('pty -> view (data)', data.length)
      if @view?
        @view.append(data, 'stdout')
    
    @child.on 'exit', (code, signal) =>
      #console.log('pty (exit)', code, signal)

      @child = null
      @pty.destroy()
      @pty = null
      
      @endTime = new Date
      if @view
        duration = ' after ' + ((@endTime - @startTime) / 1000) + ' seconds'
        if signal
          @view.setFooter('Exited with signal ' + signal + duration)
        else
          # Sometimes code seems to be null too, not sure why, perhaps a bug in node.
          code ||= 0
          @view.setFooter('Exited with status ' + code + duration)
