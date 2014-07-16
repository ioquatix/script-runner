# Script Runner

This package will run various script files inside of Atom. It currently supports JavaScript, CoffeeScript, Ruby, Python, Bash, Go and anything with a shebang line.

![Example](https://github.com/ioquatix/script-runner/raw/master/resources/screenshot-1.png)

This package is a fork of the popular `atom-runner` but with many PRs merged and other issues fixed. It includes support for shebang lines (`#!`), environment variables (via `/usr/bin/env`) and proper (currently non-interactive) terminal emulation. Many thanks to Loren Segal and all the contributing developers.

## Usage

N.B. these keyboard shortcuts are currently being reviewed, [input is welcome](https://github.com/ioquatix/script-runner/issues/1). The documentation here isn't correct.

* Hit Alt+R to launch the runner for the active window.
* Hit Ctrl+C to kill a currently running process.

Scripts which have been saved run in their directory, unsaved scripts run in the workspace root directory.

### Pseudo TTY Emulation

Most interpreters output to `stdout` and `stderr`, however the buffering mechanisms are often different when the process is not running on a PTY. For example, Ruby buffers `stdout` when not attached to a terminal which causes incorrect order of output when writing to both `stdout` and `stderr`. Additionally, most programs won't output control codes used for colouring the output when not running on a terminal. `script-runner` uses the `script` command to emulate a terminal and generally gives the best output.

### Shebang Lines

In a typical UNIX environment, the shebang line specifies the interpreter to use for the script:

```ruby
#!/usr/bin/env ruby
puts "Hello World"
```

The shebang line is the preferred way to specify how to run something as it naturally supports all the intricacies of your underlying setup, e.g. Ruby's `rvm`, Python's `virtualenv`.

Even for unsaved files without an associated grammar, as long as you have the correct shebang line it will be executed correctly.

### Environment Variables

The default process takes environment variables from the shell it was launched from. This might be an issue if launching Atom directly from the desktop environment when using, say, RVM. You can additionally specify variables using the shebang line, e.g.

```ruby
#!/usr/bin/env PATH=~/.rvm/bin:$PATH ruby
```

You can specify any environment variables you may like this way, per script.

### Configuring

This package uses the following default configuration:

```cson
'runner':
  'scopes':
    'coffee': 'coffee'
    'js': 'node'
    'ruby': 'ruby'
    'python': 'python'
    'go': 'go run'
  'extensions':
    'spec.coffee': 'jasmine-node --coffee'
```

You can add more commands for a given language scope, or add commands by
extension instead (if multiple extensions use the same syntax). Extensions
are searched before scopes (syntaxes).

To do so, add the configuration to `~/.atom/config.cson` in the format provided
above.

The mapping is `SCOPE|EXT => EXECUTABLE`, so to run JavaScript files through
phantom, you would do:

```cson
'runner':
  'scopes':
    'js': 'phantom'
```

Note that the `source.` prefix is ignored for syntax scope listings.

Similarly, in the extension map:

```cson
'runner':
  'extensions':
    'js': 'phantom'
```

Note that the `.` extension prefix is ignored for extension listings.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Desired Features

* Support for more features of DNS such as zone transfer.
* Support reverse records more easily.
* Some kind of system level integration, e.g. registering a DNS server with the currently running system resolver.

## License

Released under the MIT license. Please see `LICENSE.md` for the full license.
