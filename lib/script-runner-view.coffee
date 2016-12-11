{$, View} = require 'atom-space-pen-views'
{Emitter} = require 'atom'
OnResize = require('element-resize-detector')();
Terminal = require 'xterm'
Terminal.loadAddon 'fit'

module.exports =
class ScriptRunnerView extends View
  atom.deserializers.add(this)

  @deserialize: ({title, header, output, footer}) ->
    view = new ScriptRunnerView(title)
    view.header.html(header)
    view.output.html(output)
    view.footer.html(footer)
    return view

  @content: ->
    @div class: 'script-runner', tabindex: -1, =>
      @h1 'Script Runner'
      @div class: 'header', outlet: 'header'
      @div class: 'output', outlet: 'output'
      @div class: 'footer', outlet: 'footer'

  constructor: (title) ->
    super
    
    @emitter = new Emitter
    
    atom.commands.add 'div.script-runner', 'run:copy', => @copyToClipboard()
    
    @resizeSensor = OnResize.listenTo this.get(0), => @outputResized()
    
    @setTitle(title)
  
  serialize: ->
    deserializer: 'ScriptRunnerView'
    title: @title
    header: @header.html()
    output: @output.html()
    footer: @footer.html()

  copyToClipboard: ->
    atom.clipboard.write(window.getSelection().toString())

  getTitle: ->
    "Script Runner: #{@title}"

  setTitle: (title) ->
    @title = title
    @find('h1').html(@getTitle())

  setTheme: (theme) ->
    @theme = theme
    @attr('data-theme', theme)

  applyStyle: ->
    # remove background color in favor of the atom background
    # @term.element.style.background = null
    @term.element.style.fontFamily = (
      # atom.config.get('editor.fontFamily') or
      # (Atom doesn't return a default value if there is none)
      # so we use a poor fallback
      "monospace"
    )
    # Atom returns a default for fontSize
    @term.element.style.fontSize = (
      atom.config.get('editor.fontSize')
    ) + "px"
  
  outputResized: ->
    if @term?
      @term.fit()
  
  clear: ->
    @header.html('')
    @output.html('')
    @footer.html('')

    @term = new Terminal {
      rows: 40
      cols: 80
      scrollback: 1000,
      useStyle: no
      screenKeys: no
      handler: (data) =>
        @emitter.emit('data', data)
      cursorBlink: yes
    }
    
    parent = @output.get(0)
    @term.open(parent)
    @applyStyle()
    @term.fit()
  
  on: (event, callback) =>
    @emitter.on(event, callback)
  
  append: (text, className) ->
    @term.write(text)
  
  setHeader: (text) ->
    @header.html(text)
  
  setFooter: (text) ->
    @footer.html(text)
