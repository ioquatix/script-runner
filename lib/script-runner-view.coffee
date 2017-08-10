{$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
Terminal = require 'xterm'
Terminal.loadAddon 'fit'

module.exports =
class ScriptRunnerView extends View
  atom.deserializers.add(this)

  @deserialize: ({title, header, output}) ->
    view = new ScriptRunnerView(title)
    view.header.html(header)
    view.output.html(output)
    # view.footer.html(footer)
    return view

  @content: ->
    @div class: 'script-runner', tabindex: -1, =>
      @div class: 'header', outlet: 'header'
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
  
  serialize: ->
    deserializer: 'ScriptRunnerView'
    title: @title
    header: @header.html()
    output: @output.html()

  copyToClipboard: ->
    atom.clipboard.write(@terminal.getSelection())

  pasteToTerminal: ->
    @emitter.emit('data', atom.clipboard.read())

  getTitle: ->
    "Script Runner: #{@title}"

  setTitle: (title) ->
    @title = title
    @find('.header').html(@getTitle())

  setTheme: (theme) ->
    @theme = theme
    @attr('data-theme', theme)
  
  applyStyle: ->
    # remove background color in favor of the atom background
    # @terminal.element.style.background = null
    @terminal.element.style.fontFamily = (
      atom.config.get('editor.fontFamily') or
      # (Atom doesn't return a default value if there is none)
      # so we use a poor fallback
      "monospace"
    )
    # Atom returns a default for fontSize
    @terminal.element.style.fontSize = (
      atom.config.get('editor.fontSize')
    ) + "px"
  
  outputResized: ->
    if @terminal?
      @terminal.fit()
  
  focus: ->
    if @terminal?
      @terminal.focus()
  
  clear: ->
    if @terminal?
      @terminal.destroy()
    
    @header.html('')
    @output.html('')
    
    @terminal = new Terminal {
      rows: 40
      cols: 80
      scrollback: atom.config.get('script-runner.scrollback'),
      useStyle: no
      screenKeys: no
      handler: (data) =>
        @emitter.emit('data', data)
      cursorBlink: yes
    }
    
    @terminal.on 'resize', (geometry) =>
      @emitter.emit 'resize', geometry
    
    @terminal.open(@output.get(0), true)
    
    @applyStyle()
    @terminal.fit()
  
  on: (event, callback) =>
    @emitter.on(event, callback)
  
  append: (text, className) ->
    @terminal.write(text)
  
  log: (text) ->
    @terminal.write(text + "\r\n")
