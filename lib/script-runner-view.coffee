{ScrollView} = require 'atom-space-pen-views'
Convert = require('ansi-to-html')

module.exports =
class ScriptRunnerView extends ScrollView
  atom.deserializers.add(this)

  @deserialize: ({title, linecount, header, output, footer}) ->
    view = new ScriptRunnerView(title)
    view.linecount = linecount
    view._header.html(header)
    view._output.html(output)
    view._footer.html(footer)
    return view

  @content: ->
    @div class: 'script-runner', tabindex: -1, =>
      @h1 'Script Runner'
      @div class: 'header'
      @pre class: 'output'
      @div class: 'footer'

  constructor: (title) ->
    super
    
    atom.commands.add 'div.script-runner', 'run:copy', => @copyToClipboard()
    
    @convert = new Convert({escapeXML: true})
    @linecount = 0
    @_header = @find('.header')
    @_output = @find('.output')
    @_footer = @find('.footer')
    @setTitle(title)

  serialize: ->
    deserializer: 'ScriptRunnerView'
    title: @title
    linecount: @linecount
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

  clear: ->
    @linecount = 0
    @_output.html('')
    @_header.html('')
    @_footer.html('')

  append: (text, className) ->
    # console.log @_output.find('span:first-child')
    if @linecount >= atom.config.get('script-runner.scrollbackDistance')
      # console.log 'removing'
      @_output.find(':first-child').remove()
    
    span = document.createElement('span')
    span.innerHTML = @convert.toHtml([text])
    span.className = className || 'stdout'
    @_output.append(span)
    @linecount += 1

  header: (text) ->
    @_header.html(text)

  footer: (text) ->
    @_footer.html(text)
