{ConfigObserver} = require 'atom'

spawn = require('child_process').spawn
fs = require('fs')
url = require('url')
shellwords = require('shellwords')

ScriptRunnerView = require './script-runner-view'

class ScriptRunner
  cfg:
    ext: 'runner.extensions'
    scope: 'runner.scopes'

  defaultExtensionMap:
    'spec.coffee': 'jasmine-node --coffee',
    'sh' : 'bash'

  defaultScopeMap:
    '^source.coffee': 'coffee'
    '^source.js': 'node'
    '^source.ruby': 'ruby'
    '^source.python': 'python'
    '^source.go': 'go run'
    '^text.html.php': 'php'
    'Shell Script (Bash)': 'bash'

  extensionMap: null
  scopeMap: null

  destroy: ->
    atom.config.unobserve @cfg.ext
    atom.config.unobserve @cfg.scope

  activate: ->
    @runnerView = null
    atom.config.setDefaults @cfg.ext, @defaultExtensionMap
    atom.config.setDefaults @cfg.scope, @defaultScopeMap
    atom.config.observe @cfg.ext, =>
      @extensionMap = atom.config.get(@cfg.ext)
    atom.config.observe @cfg.scope, =>
      @scopeMap = atom.config.get(@cfg.scope)
    atom.workspaceView.command 'runner:run', => @run()
    atom.workspaceView.command 'runner:stop', => @stop()

  run: ->
    editor = atom.workspace.getActiveEditor()
    return unless editor?

    path = editor.getPath()
    cmd = @commandFor(editor)
    unless cmd?
      console.warn("No registered executable for file '#{path}'")
      return

    previousPane = atom.workspaceView.getActivePaneView()
    if not @runnerView? or atom.workspaceView.find('.script-runner').size() == 0
      @runnerView = new ScriptRunnerView(editor.getTitle())
      panes = atom.workspaceView.getPaneViews()
      @pane = panes[panes.length - 1].splitRight(@runnerView)

    @runnerView.setTitle(editor.getTitle())
    if @pane and @pane.isOnDom()
      @pane.activateItem(@runnerView)
    @execute(cmd, editor)

  stop: ->
    if @child
      @child.kill()
      @child = null
      if @runnerView
        @runnerView.append('^C', 'stdin')

  runnerView: null
  pane: null

  execute: (cmd, editor) ->
    # Stop any previous command?
    @stop()
    @runnerView.clear()

    # Save the file if it has been modified:
    if editor.getPath()
      editor.save()
    
    # If the editor refers to a buffer on disk which has not been modified, we can use it directly:
    if editor.getPath() and !editor.buffer.isModified()
      cmd = cmd + ' ' + editor.getPath()
      appendBuffer = false
    else
      appendBuffer = true
    
    # PTY emulation:
    args = ["script", "-qfc", cmd, "/dev/null"]
    
    # Spawn the child process:
    @child = spawn(args[0], args.slice(1), cwd: atom.project.path)
    @child.stderr.on 'data', (data) =>
      @runnerView.append(data, 'stderr')
      @runnerView.scrollToBottom()
    @child.stdout.on 'data', (data) =>
      @runnerView.append(data, 'stdout')
      @runnerView.scrollToBottom()
    @child.on 'close', (code, signal) =>
      @runnerView.footer('Exited with status ' + code + ' in ' +
        ((new Date - startTime) / 1000) + ' seconds')
      @child = null

    startTime = new Date
    
    # Could not supply file name:
    if appendBuffer
      @child.stdin.write(editor.getText())
    
    @runnerView.header('Running: ' + cmd)
    @child.stdin.end()

  commandFor: (editor) ->
    # try to extract from the shebang line
    firstLine = editor.buffer.getLines()[0]
    if firstLine.match('^#!')
      #console.log("firstLine", firstLine)
      return firstLine.substr(2)
    
    # try to lookup by extension
    if editor.getPath()?
      for ext in Object.keys(@extensionMap).sort((a,b) -> b.length - a.length)
        #console.log("Matching extension", ext)
        if editor.getPath().match('\\.' + ext + '$')
          #console.log("Matched extension", ext)
          return @extensionMap[ext]

    # lookup by grammar
    scope = editor.getCursorScopes()[0]
    for pattern in Object.keys(@scopeMap)
      #console.log("Matching scope", name, "with", scope)
      if scope.match(pattern)
        #console.log("Matched scope", name, "with", pattern)
        return @scopeMap[pattern]

module.exports = new ScriptRunner
