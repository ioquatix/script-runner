{$, View} = require 'atom-space-pen-views'
XTerm = require('xterm')
XTerm.loadAddon('fit')

module.exports =
class ScriptRunnerView extends View
  atom.deserializers.add(this)

  @deserialize: ({title, header, output, footer}) ->
    view = new ScriptRunnerView(title)
    view._header.html(header)
    view._output.html(output)
    view._footer.html(footer)
    return view

  @content: ->
    @div class: 'script-runner', tabindex: -1, =>
      @h1 'Script Runner'
      @div class: 'header'
      @div class: 'output'
      @div class: 'footer'

  constructor: (title) ->
    super
    
    atom.commands.add 'div.script-runner', 'run:copy', => @copyToClipboard()
    
    @_header = @find('.header')
    @_output = @find('.output')
    @_footer = @find('.footer')
    
    @setTitle(title)
  
  serialize: ->
    deserializer: 'ScriptRunnerView'
    title: @title
    header: @_header.html()
    output: @_output.html()
    footer: @_footer.html()

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

  clear: ->
    @_header.html('')
    
    @xterm = new XTerm {
      useStyle: no
      screenKeys: no
      rows: 40
      cols: 80
    }
    
    parent = @_output.get(0)
    @xterm.open(parent)
    @xterm.fit()
    
    @_footer.html('')

  append: (text, className) ->
    @xterm.write(text)

  header: (text) ->
    @_header.html(text)

  footer: (text) ->
    @_footer.html(text)
