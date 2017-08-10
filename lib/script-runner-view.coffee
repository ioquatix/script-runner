{$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
Terminal = require 'xterm'
Terminal.loadAddon 'fit'

module.exports =
class ScriptRunnerView extends View
  atom.deserializers.add(this)

  @deserialize: ({title, output}) ->
    view = new ScriptRunnerView(title)
    view.output.html(output)
    return view

  @content: ->
    @div class: 'script-runner', tabindex: -1, =>
      @div class: 'output', outlet: 'output'
    
  constructor: (title) ->
    super
    
    @emitter = new Emitter
    
    atom.commands.add @element,
      'script-runner:copy': => @copyToClipboard()
      'script-runner:paste': => @pasteToTerminal()
    
    @resizeObserver = new ResizeObserver => @outputResized()
    @resizeObserver.observe @get(0)
    
    @setTitle(title)
    @setupTerminal()
  
  serialize: ->
    deserializer: 'ScriptRunnerView'
    title: @title
    output: @output.html()

  copyToClipboard: ->
    atom.clipboard.write(@terminal.getSelection())

  pasteToTerminal: ->
    @emitter.emit('data', atom.clipboard.read())

  getIconName: ->
    'terminal'

  getTitle: ->
    "Script Runner: #{@title}"

  setTitle: (title) ->
    @title = title

  setTheme: (theme) ->
    @theme = theme
    @attr('data-theme', theme)
  
  setupTerminal: ->
    @terminal = new Terminal {
      rows: 40
      cols: 80
      scrollback: atom.config.get('script-runner.scrollback'),
      useStyle: no
      screenKeys: no
      cursorBlink: yes
    }
    
    @terminal.on 'resize', (geometry) =>
      @emitter.emit('resize', geometry)
    
    @terminal.on 'data', (data) =>
      @emitter.emit('data', data)
    
    @terminal.on 'key', (key, event) =>
      @emitter.emit('key', event)
    
    # remove background color in favor of the atom background
    # @terminal.element.style.background = null
    @output.css 'font-family', (
      atom.config.get('editor.fontFamily') or
      # (Atom doesn't return a default value if there is none)
      # so we use a poor fallback
      "monospace"
    )
    
    # Atom returns a default for fontSize
    @output.css 'font-size', (
      atom.config.get('editor.fontSize')
    ) + "px"
    
    @terminal.open(@output.get(0), true)
    @terminal.fit()
  
  outputResized: ->
    if @terminal?
      @terminal.fit()
      
      # @emitter.emit('resize', @terminal.geometry)
  
  focus: ->
    if @terminal?
      @terminal.focus()
  
  clear: ->
    @terminal.clear()
  
  on: (event, callback) =>
    @emitter.on(event, callback)
  
  append: (text, className) ->
    @terminal.write(text)
  
  log: (text) ->
    @terminal.write(text + "\r\n")
