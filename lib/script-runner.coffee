{ConfigObserver} = require 'atom'

ScriptRunnerProcess = require './script-runner-process'
ScriptRunnerView = require './script-runner-view'

ChildProcess = require 'child_process'
ShellEnvironment = require 'shell-environment'

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
    @killAllProcesses()

  activate: ->
    @runners = [] # this is just for keeping track of runners
    # keeps track of runners as {editor: editor, view: ScriptRunnerView, process: ScriptRunnerProcess}
    @runnerPane = null
    
    # register commands
    atom.commands.add 'atom-workspace',
      'run:script': (event) => @run(),
      'run:terminate': (event) => @stop()

  killProcess: (runner, detach = false)->
    if runner?
      if runner.process?
        runner.process.stop('SIGTERM')
        if detach
          # Don't render into the view any more:
          runner.process.detach()
          runner.process = null
  
  killAllProcesses: (detach = false) ->
    # Kills all the running processes
    for runner in @runners
      if runner.process?
        runner.process.stop('SIGTERM')
        
        if detach
          runner.process.detach()
          runner.process = null

  createRunnerView: (editor) ->
    if not @pane?
      # creates a new pane if there isn't one yet
      @pane = atom.workspace.getActivePane().splitRight()
      @pane.onDidDestroy () =>
        @killAllProcesses(true)
        @pane = null
      
      @pane.onWillDestroyItem (evt) =>
        # kill the process of the removed view and scratch it from the array
        runner = @getRunnerBy(evt.item)
        @killProcess(runner, true)
    
    runner = @getRunnerBy(editor, 'editor')
    
    if not runner?
      runner = {editor: editor, view: new ScriptRunnerView(editor.getTitle()), process: null}
      @runners.push(runner)
    
    else
      runner.view.setTitle(editor.getTitle()) # if it changed
    
    return runner

  run: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?
    
    path = editor.getPath()
    cmd = @commandFor(editor)
    unless cmd?
      alert("Not sure how to run '#{path}' :/")
      return false
    
    runner = @createRunnerView(editor)
    @killProcess(runner, true)
    
    @pane.activateItem(runner.view)
    
    runner.view.clear()
    
    ShellEnvironment.loginEnvironment (error, environment) =>
      if environment
        runner.process = ScriptRunnerProcess.run(runner.view, cmd, environment, editor)
      else
        throw new Error error

  stop: ->
    unless @pane
      return
    
    runner = @getRunnerBy(@pane.getActiveItem())
    @killProcess(runner)

  commandFor: (editor) ->
    # Try to extract from the shebang line:
    firstLine = editor.lineTextForBufferRow(0)
    if firstLine.match('^#!')
      #console.log("firstLine", firstLine)
      return firstLine.substr(2)
    
    # Lookup using the command map:
    path = editor.getPath()
    scope = editor.getRootScopeDescriptor().scopes[0]
    for method in @commandMap
      if method.fileName and path?
        if path.match(method.path)
          return method.command
      else if method.scope
        if scope.match(method.scope)
          return method.command
  
  getRunnerBy: (attr_obj, attr_name = 'view') ->
    # Finds the runner object either by view, editor, or process
    for runner in @runners
      if runner[attr_name] is attr_obj
        return runner
    
    return null

module.exports = new ScriptRunner
