# Script Runner

This package will run various script files inside of Atom. It currently supports JavaScript, CoffeeScript, Ruby, Python, Bash, Go and anything with a shebang line.

![Example](https://github.com/ioquatix/script-runner/raw/master/resources/screenshot-1.png)

This package is a fork of the popular `atom-runner` but with many PRs merged and other issues fixed. It includes support for shebang lines (`#!`), correctly setting the environment (e.g. `RVM` supported out of the box) and proper terminal emulation using [pty.js](https://github.com/chjj/pty.js/) and [xterm](https://github.com/sourcelair/xterm.js/). Many thanks to Loren Segal and all the contributing developers.

## Usage

N.B. these keyboard shortcuts are currently being reviewed, [input is welcome](https://github.com/ioquatix/script-runner/issues/1).

| Command              | Mac OS X          | Linux            |
|----------------------|-------------------|------------------|
| Run: Script          | <kbd>ctrl-x</kbd> | <kbd>alt-x</kbd> |
| Run: Terminate       | <kbd>ctrl-c</kbd> | <kbd>alt-c</kbd> |

Scripts which have been saved run in their directory, unsaved scripts run in the workspace root directory.

The Run: Script command is used script-runner will check if there is already an output view dedicated to the script in the text editor in focus. If there isn't one a new one will be created otherwise it will clear the already existing one and reuse it.

Closing a runner view will cause its process to terminate to avoid losing control over scripts executed with this plugin.

### `node-gyp` failures

If you get issues about loading node-pty, you might have a problem with your python install. `node-gyp` [doesn't work if `python` points to `python3`](https://github.com/nodejs/node-gyp/issues/1030). To fix this, tell `apm` to prefer python2.7

	apm config set python $(which python2.7)

Once you've done this, reinstall script-runner.

### Run Selection

When invoking the above `Run: Script` command, if a portion of the script is selected, only that portion will be executed.

### User Input

When running a script, the focus will be passed to the script output terminal. You are welcome to use the keyboard and mouse to interact with the running program.

### Shebang Lines

In a typical UNIX environment, the shebang line specifies the interpreter to use for the script:

```ruby
#!/usr/bin/env ruby
puts "Hello World"
```

The shebang line is the preferred way to specify how to run something as it naturally supports all the intricacies of your underlying setup, e.g. Ruby's `rvm`, Python's `virtualenv`.

Even for unsaved files without an associated grammar, as long as you have the correct shebang line it will be executed correctly.

### Environment Variables

The default Atom process takes environment variables from the shell it was launched from. This might be an issue if launching Atom directly from the desktop environment when using, say, RVM which exports functionality for interactive terminal sessions.

To ensure consistent behavior, when running a script, environment variables are extracted from the [interactive login shell](). This usually loads the same environment variables you'd expect when using the terminal.

## Configuration

### Split Direction

It is possible to configure which way to split the new pane. Open your Atom config file and edit `'script-runner'.splitDirection`, the possible
values are: `'up'`, `'down'`, `'left'` and `'right'`. For example:

```cson
"*":
	//...
	'script-runner':
		`splitDirection`: `down`
```

### Scrollback Distance

To limit the number of lines kept in the output window simply edit the `'script-runner'.scrollback` option in
your Atom config file.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license. Please see `LICENSE.md` for the full license.
