import PTY from 'node-pty';
import OS from 'os';
import Path from 'path';
import Shellwords from 'shellwords';
import TempWrite from 'temp-write';

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
		this.pty = null;
		
		if (atom.config.get('script-runner.clearBeforeExecuting')) {
			this.view.clear();
		}
	}
	
	destroy() {
		if (this.pty) {
			this.pty.kill('SIGTERM')
			this.pty.destroy();
		}
	}
	
	kill(signal) {
		if (signal == null) { signal = 'SIGINT'; }
		if (this.pty) {
			console.log("Sending", signal, "to child", this.pty, "pid", this.pty.pid);
			this.pty.kill(signal);
			if (this.view) {
				this.view.log(`<Sending ${signal}>`, 'stdin');
			}
		}
	}
	
	resolvePath(editor, callback) {
		if (editor.getPath()) {
			const cwd = Path.dirname(editor.getPath());
			
			// Save the file if it has been modified:
			Promise.resolve(editor.save()).then(() => {
				callback(editor.getPath(), cwd);
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
		
		if (selection != null && !selection.isEmpty()) {
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
		
		this.pty = PTY.spawn(args[0], args.slice(1), {
			cols: this.view.terminal.cols,
			rows: this.view.terminal.rows,
			cwd: cwd,
			env: env,
			name: 'xterm-color',
		});
		
		this.startTime = new Date;
		
		// Update the status (*Shellwords.join doesn't exist yet):
		//this.view.log(args.join(' ') + ' (pgid ' + this.pty.pid + ')');
		
		if (this.view.process) {
			this.view.process.destroy();
		}
		
		this.view.process = this;
		
		const {terminal} = this.view;
		
		this.view.on('paste', data => {
			// console.log('view -> pty (paste)', data.length);
			if (this.pty) {
				this.pty.write(data);
			}
		});
		
		terminal.on('data', data => {
			// console.log('view -> pty (data)', data.length);
			if (this.pty) {
				this.pty.write(data);
			}
		});
		
		terminal.on('resize', geometry => {
			if (this.pty) {
				// console.log('view -> pty (resize)', geometry);
				this.pty.resize(geometry.cols, geometry.rows);
			}
		});
		
		this.pty.on('exit', () => {
			// console.log('pty (exit)')
		});
		
		// Handle various events relating to the child process:
		this.pty.on('data', data => {
			// console.log('pty -> view (data)', data.length);
			terminal.write(data);
		});
		
		this.pty.on('error', what => {
			console.log('pty (error)', what);
		});
		
		this.pty.on('exit', (code, signal) => {
			console.log('pty (exit)', code, signal)
			
			this.pty.destroy();
			this.pty = null;
			
			this.endTime = new Date;
			if (this.view) {
				const duration = ` after ${(this.endTime - this.startTime) / 1000} seconds`;
				if (signal) {
					this.view.log(`Exited with signal ${signal}${duration}`);
				} else if (code && code != 0) {
					this.view.log(`Exited with status ${code}${duration}`);
				}
			}
		});
		
		terminal.focus();
	}
};

module.exports = ScriptRunnerProcess;
