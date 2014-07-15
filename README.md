# Script Runner

This package will run various script files inside of Atom.
It currently supports JavaScript, CoffeeScript, Ruby, Python, Bash, and Go. You can add more.

![Example](http://github.com/ioquatix/script-runner/raw/master/resources/screenshot-1.png)

This package is a fork of the popular `atom-runner` but with many PRs merged and other issues fixed. It includes support for shebang lines (`#!`), environment variables (via `/usr/bin/env`) and proper (currently non-interactive) terminal emulation. Many thanks to Loren Segal and all the contributing developers.

## Usage

* Hit Alt+R to launch the runner for the active window.
* Hit Ctrl+C to kill a currently running process.

N.B. these keyboard shortcuts are currently being reviewed, [input is welcome](https://github.com/ioquatix/script-runner/issues/1).

Scripts which have been saved run in their directory, unsaved scripts run in the workspace root directory.

### Pseudo TTY Emulation

Most interpreters output to `stdout` and `stderr`, however the buffering mechanisms are often different when the process is not running on a PTY. For example, Ruby buffers `stdout` when not attached to a terminal which causes incorrect order of output when writing to both `stdout` and `stderr`. Additionally, most programs won't output control codes used for colouring the output when not running on a terminal. `script-runner` uses the `script` command to emulate a terminal and generally gives the best output.

### Shebang Lines

In a typical unix environment, the shebang line specifies the interpreter to use for the script:

```ruby
#!/usr/bin/env ruby
puts "Hello World"
```

Even for unsaved files without an associated grammar, as long as you have the correct shebang line it will be executed correctly.

### Environment Variables

The default process takes environment variables from the shell it was launched from. This might be an issue if launching Atom directly from the desktop environment when using, say, RVM. You can additionally specify variables using the shebang line, e.g.

```ruby
#!/usr/bin/env PATH=~/.rvm/bin:$PATH ruby
```

You can specify any environment variables you may like this way, per script.

## Configuring

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
