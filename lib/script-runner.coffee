{ConfigObserver} = require 'atom'

ScriptRunnerProcess = require './script-runner-process'
ScriptRunnerView = require './script-runner-view'

ChildProcess = require 'child_process'

class ScriptRunner
  commandMap: [
    {scope: '^source\\.coffee', command: 'coffee'}
    {scope: '^source\\.js', command: 'node'}
    {scope: '^source\\.ruby', command: 'ruby'}
    {scope: '^source\\.python', command: 'python'}
    {scope: '^source\\.go', command: 'go run'}
    {scope: '^text\\.html\\.php', command: 'php'}
    {scope: 'Shell Script (Bash)', command: 'bash'}
    {path: 'spec\\.coffee$', command: 'jasmine-node --coffee'},
    {path: '\\.sh$', command: 'bash'}
  ]

  destroy: ->
    @killProcess()

  activate: ->
    @runnerView = null
    atom.workspaceView.command 'run:script', => @run()
    atom.workspaceView.command 'run:terminate', => @stop()

  fetchShellEnvironment: (callback) ->
    # I tried using ChildProcess.execFile but there is no way to set detached and this causes the child shell to lock up. This command runs an interactive login shell and executes the export command to get a list of environment variables. We then use these to run the script:
    child = ChildProcess.spawn process.env.SHELL, ['-ilc', 'export'],
      # This is essential for interactive shells, otherwise it never finishes:
      detached: true,
      # We don't care about stdin, stderr can go out the usual way:
      stdio: ['ignore', 'pipe', process.stderr]
    
    # We buffer stdout:
    buffer = ''
    child.stdout.on 'data', (data) -> buffer += data
    
    # When the process finishes, extract the environment variables and pass them to the callback:
    child.on 'close', (code, signal) ->
      environment = {}
      for definition in buffer.split('\n')
        [key, value] = definition.split('=', 2)
        environment[key] = value if key != ''
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
      
      # handle the destruction of the pane.
      @pane.onDidDestroy () =>
        @killProcess()
    
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
    # Try to extract from the shebang line:
    firstLine = editor.buffer.getLines()[0]
    if firstLine.match('^#!')
      #console.log("firstLine", firstLine)
      return firstLine.substr(2)
    
    # Lookup using the command map:
    path = editor.getPath()
    scope = editor.getCursorScopes()[0]
    for method in @commandMap
      if method.fileName and path?
        if path.match(method.path)
          return method.command
      else if method.scope
        if scope.match(method.scope)
          return method.command

module.exports = new ScriptRunner
