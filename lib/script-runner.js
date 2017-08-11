/** @babel */

const ScriptRunnerProcess = require('./script-runner-process');
const ScriptRunnerView = require('./script-runner-view');

const ChildProcess = require('child_process');
const ShellEnvironment = require('shell-environment');

const Path = require('path');
const Shellwords = require('shellwords');
const {CompositeDisposable} = require('atom');

// const SCRIPT_RUNNER_URI = 'script-runner://';

export default {
	config: {
		splitDirection: {
			type: 'string',
			default: 'right',
			enum: ['left', 'right', 'up', 'down']
		},

		scrollbackDistance: {
			type: 'number',
			default: 555
		},

		theme: {
			type: 'string',
			default: 'light',
			enum: [
				{value: 'light', description: "Light"},
				{value: 'dark', description: "Dark"}
			]
		}
	},
	
	commandMap: [
		{scope: '^source\\.coffee', command: 'coffee'},
		{scope: '^source\\.js', command: 'node'},
		{scope: '^source\\.ruby', command: 'ruby'},
		{scope: '^source\\.python', command: 'python'},
		{scope: '^source\\.go', command: 'go run'},
		{scope: '^text\\.html\\.php', command: 'php'},
		{scope: 'Shell Script (Bash)', command: 'bash'},
		{path: 'spec\\.coffee$', command: 'jasmine-node --coffee'},
		{path: '\\.sh$', command: 'bash'}
	],
	
	disposables: null,
	
	// keeps track of runners as {editor: editor, view: ScriptRunnerView, process: ScriptRunnerProcess}
	runners: [],
	
	activate() {
		this.disposables = new CompositeDisposable();
		
		// register commands
		this.disposables.add(
			atom.commands.add('atom-workspace', {
				'script-runner:run': event => this.run(),
				'script-runner:terminate': event => this.stop(),
				'script-runner:shell': event => this.runShell()
			})
		);
	},
	
	deactivate() {
		this.killAllProcesses();
		
		this.disposables.dispose();
	},
	
	killProcess(runner, detach) {
		if (runner != null) {
			if (runner.process != null) {
				runner.process.stop('SIGTERM');
				if (detach) {
					// Don't render into the view any more:
					runner.process.detach();
					return runner.process = null;
				}
			}
		}
	},

	killAllProcesses(detach) {
		// Kills all the running processes
		for (let runner of Array.from(this.runners)) {
			if (runner.process != null) {
				runner.process.stop('SIGTERM');

				if (detach) {
					runner.process.detach();
					runner.process = null;
				}
			}
		}
	},

	createRunnerView(editor) {
		if (!this.pane) {
			// creates a new pane if there isn't one yet
			switch (atom.config.get('script-runner.splitDirection')) {
				case 'up': this.pane = atom.workspace.getActivePane().splitUp(); break;
				default:
				case 'down': this.pane = atom.workspace.getActivePane().splitDown(); break;
				case 'left': this.pane = atom.workspace.getActivePane().splitLeft(); break;
				case 'right': this.pane = atom.workspace.getActivePane().splitRight(); break;
			}

			this.pane.onDidDestroy(() => {
				this.killAllProcesses(true);
				return this.pane = null;
			});

			this.pane.onWillDestroyItem(event => {
				// kill the process of the removed view and scratch it from the array
				let runner = this.getRunnerBy(event.item);
				return this.killProcess(runner, true);
			});
		}

		let runner = this.getRunnerBy(editor, 'editor');

		if (runner == null) {
			runner = {editor, view: new ScriptRunnerView(editor.getTitle()), process: null};
			this.runners.push(runner);
		} else {
			runner.view.setTitle(editor.getTitle()); // if it changed
		}

		runner.view.setTheme(atom.config.get('script-runner.theme'));
		return runner;
	},

	runShell() {
		const editor = atom.workspace.getActiveTextEditor();
		if (editor == null) { return; }

		const path = Path.dirname(editor.getPath());

		const runner = this.createRunnerView(editor);
		this.killProcess(runner, true);

		this.pane.activateItem(runner.view);

		runner.view.clear();

		return ShellEnvironment.loginEnvironment((error, environment) => {
			if (environment) {
				const cmd = environment['SHELL'];
				const args = Shellwords.split(cmd).concat("-l");
				
				return runner.process = ScriptRunnerProcess.spawn(runner.view, args, path, environment);
			} else {
				throw new Error(error);
			}
		});
	},

	run() {
		const editor = atom.workspace.getActiveTextEditor();
		if (editor == null) { return; }

		const path = editor.getPath();
		const cmd = this.commandFor(editor);
		if (cmd == null) {
			alert(`Not sure how to run '${path}' :/`);
			return false;
		}

		const runner = this.createRunnerView(editor);
		this.killProcess(runner, true);

		this.pane.activateItem(runner.view);

		runner.view.clear();

		return ShellEnvironment.loginEnvironment((error, environment) => {
			if (environment) {
				return runner.process = ScriptRunnerProcess.run(runner.view, cmd, environment, editor);
			} else {
				throw new Error(error);
			}
		});
	},

	stop() {
		if (!this.pane) {
			return;
		}

		const runner = this.getRunnerBy(this.pane.getActiveItem());
		return this.killProcess(runner);
	},

	commandFor(editor) {
		// Try to extract from the shebang line:
		const firstLine = editor.lineTextForBufferRow(0);
		if (firstLine.match('^#!')) {
			//console.log("firstLine", firstLine)
			return firstLine.substr(2);
		}

		// Lookup using the command map:
		const path = editor.getPath();
		const scope = editor.getRootScopeDescriptor().scopes[0];
		for (let method of Array.from(this.commandMap)) {
			if (method.fileName && (path != null)) {
				if (path.match(method.path)) {
					return method.command;
				}
			} else if (method.scope) {
				if (scope.match(method.scope)) {
					return method.command;
				}
			}
		}
	},

	getRunnerBy(attr_obj, attr_name) {
		// Finds the runner object either by view, editor, or process
		if (attr_name == null) { attr_name = 'view'; }
		for (let runner of Array.from(this.runners)) {
			if (runner[attr_name] === attr_obj) {
				return runner;
			}
		}

		return null;
	},
};
