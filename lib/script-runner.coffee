{ConfigObserver} = require 'atom'

ScriptRunnerProcess = require './script-runner-process'
ScriptRunnerView = require './script-runner-view'

ChildProcess = require 'child_process'

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
    @killProcess()

  activate: ->
    @runnerView = null
    atom.config.setDefaults @cfg.ext, @defaultExtensionMap
    atom.config.setDefaults @cfg.scope, @defaultScopeMap
    atom.config.observe @cfg.ext, =>
      @extensionMap = atom.config.get(@cfg.ext)
    atom.config.observe @cfg.scope, =>
      @scopeMap = atom.config.get(@cfg.scope)
    atom.workspaceView.command 'run:script', => @run()
    atom.workspaceView.command 'run:terminate', => @stop()

  fetchShellEnvironment: (callback) ->
    exportsCommand = process.env.SHELL + " -lc export"
    environment = {}
    
    # Run the command and update the local process environment:
    ChildProcess.exec exportsCommand, (error, stdout, stderr) ->
      for definition in stdout.trim().split('\n')
        [key, value] = definition.split('=', 2)
        environment[key] = value
      callback(environment)

  killProcess: (detach = false)->
    if @process?
      @process.stop('SIGTERM')
      if detach
        # Don't render into the view any more:
        @process.detach()
        @process = null

  createRunnerView: (editor) ->
    scriptRunners = []
    
    # Find all existing ScriptRunnerView instances:
    for pane in atom.workspace.getPanes()
      for item in pane.items
        scriptRunners.push({pane: pane, view: item}) if item instanceof ScriptRunnerView
    
    if scriptRunners.length == 0
      @runnerView = new ScriptRunnerView(editor.getTitle())
      panes = atom.workspace.getPanes()
      @pane = panes[panes.length - 1].splitRight(items: [@runnerView])
    else
      @runnerView = scriptRunners[0].view
      @pane = scriptRunners[0].pane

  run: ->
    editor = atom.workspace.getActiveEditor()
    return unless editor?
    
    path = editor.getPath()
    cmd = @commandFor(editor)
    unless cmd?
      alert("Not sure how to run '#{path}' :/")
      return false
    
    @killProcess(true)
    @createRunnerView(editor)
    
    @runnerView.setTitle(editor.getTitle())
    @pane.activateItem(@runnerView)
    
    @runnerView.clear()
    # In the future it may be useful to support multiple runner views:
    @fetchShellEnvironment (env) =>
      @process = ScriptRunnerProcess.run(@runnerView, cmd, env, editor)

  stop: ->
    @killProcess()

  runnerView: null
  pane: null

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
