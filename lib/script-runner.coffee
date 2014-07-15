{ConfigObserver} = require 'atom'

ScriptRunnerProcess = require './script-runner-process'
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
    @killAllProcesses()

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

  killAllProcesses: ->
    if @process?
      # Don't render into the view
      @process.detach()
      @process.stop('SIGTERM')

  createRunnerView: (editor) ->
    scriptRunners = atom.workspaceView.find('.script-runner')
    
    scriptRunners.remove();
    
    @runnerView = new ScriptRunnerView(editor.getTitle())
    panes = atom.workspaceView.getPaneViews()
    @pane = panes[panes.length - 1].splitRight(@runnerView)

  run: ->
    editor = atom.workspace.getActiveEditor()
    return unless editor?
    
    path = editor.getPath()
    cmd = @commandFor(editor)
    unless cmd?
      alert("No registered executable for file '#{path}'")
      return
    
    @killAllProcesses()
    @createRunnerView(editor)
    
    @runnerView.setTitle(editor.getTitle())
    if @pane and @pane.isOnDom()
      @pane.activateItem(@runnerView)
    
    @runnerView.clear()
    # In the future it may be useful to support multiple runner views:
    @process = ScriptRunnerProcess.run(@runnerView, cmd, editor)

  stop: (signal = 'SIGINT') ->
    @killAllProcesses(signal)

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
