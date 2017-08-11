/** @babel */

const ChildProcess = require('child_process');
const PTY = require('node-pty');
const OS = require('os');
const Path = require('path');
const Shellwords = require('shellwords');
const TempWrite = require('temp-write');

class ScriptRunnerProcess {
	static run(view, cmd, env, editor) {
		const scriptRunnerProcess = new ScriptRunnerProcess(view);
		
		scriptRunnerProcess.execute(cmd, env, editor);
		
		return scriptRunnerProcess;
	}
	
	static spawn(view, args, cwd, env) {
		const scriptRunnerProcess = new ScriptRunnerProcess(view);
		
		scriptRunnerProcess.spawn(args, cwd, env);
		
		return scriptRunnerProcess;
	}
	
	constructor(view) {
		this.view = view;
		this.child = null;
	}
	
	detach() {
		return this.view = null;
	}
	
	stop(signal) {
		if (signal == null) { signal = 'SIGINT'; }
		if (this.child) {
			console.log("Sending", signal, "to child", this.child, "pid", this.child.pid);
			process.kill(-this.child.pid, signal);
			if (this.view) {
				return this.view.log(`<Sending ${signal}>`, 'stdin');
			}
		}
	}
	
	resolvePath(editor, callback) {
		if (editor.getPath()) {
			const cwd = Path.dirname(editor.getPath());
			
			// Save the file if it has been modified:
			Promise.resolve(editor.save()).then(() => {
				return callback(editor.getPath(), cwd);
			});
			
			return true;
		}
		
		// Otherwise it was not handled:
		return false;
	}
	
	resolveSelection(editor, callback) {
		let cwd;
		if (editor.getPath()) {
			cwd = Path.dirname(editor.getPath());
		} else {
			cwd = atom.project.path;
		}
		
		const selection = editor.getLastSelection();
		
		if ((selection != null) && !selection.isEmpty()) {
			callback(selection.getText(), cwd);
			return true;
		}
		
		// Otherwise it was not handled:
		return false;
	}
	
	resolveBuffer(editor, callback) {
		let cwd;
		if (editor.getPath()) {
			cwd = Path.dirname(editor.getPath());
		} else {
			cwd = atom.project.path;
		}
		
		callback(editor.getText(), cwd);
		
		return true;
	}
	
	execute(cmd, env, editor) {
		// Split the incoming command so we can modify it
		const args = Shellwords.split(cmd);
		
		if (this.resolveSelection(editor, (text, cwd) => {
			args.push(TempWrite.sync(text));
			return this.spawn(args, cwd, env);
		})) { return true; }
		
		if (this.resolvePath(editor, (path, cwd) => {
			args.push(path);
			return this.spawn(args, cwd, env);
		})) { return true; }
		
		if (this.resolveBuffer(editor, (text, cwd) => {
			args.push(TempWrite.sync(text));
			return this.spawn(args, cwd, env);
		})) { return true; }
		
		// something really has to go wrong for this.
		return false;
	}
	
	spawn(args, cwd, env) {
		// Spawn the child process:
		console.log("spawn", args[0], args.slice(1), cwd, env);
		
		env['TERM'] = 'xterm-256color';
		
		this.pty = PTY.open({
			cols: this.view.terminal.cols,
			rows: this.view.terminal.rows
		});
		
		this.child = ChildProcess.spawn(args[0], args.slice(1), {cwd, env, stdio: [this.pty.slave, this.pty.slave, this.pty.slave], detached: true});
		this.pty.slave.end();
		
		this.startTime = new Date;
		
		// Update the status (*Shellwords.join doesn't exist yet):
		this.view.log(args.join(' ') + ' (pgid ' + this.child.pid + ')');
		
		const { terminal } = this.view;
		
		terminal.on('data', data => {
			console.log('view -> pty (data)', data.length);
			if (this.pty != null) {
				return this.pty.master.write(data);
			}
		});
		
		// terminal.on 'key', (event) =>
		//   if @child?
		//     if event.keyCode == 67 and event.ctrlKey
		//       console.log('process.kill', -@child.pid, 'SIGINT')
		//       process.kill(-@child.pid, 'SIGINT')
		
		terminal.on('resize', geometry => {
			if (this.pty != null) {
				console.log('view -> pty (resize)', geometry);
				return this.pty.resize(geometry.cols, geometry.rows);
			}
		});
		
		terminal.focus();
		
		// Handle various events relating to the child process:
		this.pty.master.on('data', data => {
			console.log('pty -> view (data)', data.length);
			return terminal.write(data);
		});
			// if @view?
			//   @view.append(data, 'stdout')
		
		this.child.on('error', what => {
			return console.log('pty (error)', what);
		});
		
		return this.child.on('exit', (code, signal) => {
			//console.log('pty (exit)', code, signal)

			this.child = null;
			this.pty.destroy();
			this.pty = null;
			
			this.endTime = new Date;
			if (this.view) {
				const duration = ` after ${(this.endTime - this.startTime) / 1000} seconds`;
				if (signal) {
					return this.view.log(`Exited with signal ${signal}${duration}`);
				} else {
					// Sometimes code seems to be null too, not sure why, perhaps a bug in node.
					if (!code) { code = 0; }
					return this.view.log(`Exited with status ${code}${duration}`);
				}
			}
		});
	}
};

module.exports = ScriptRunnerProcess;
