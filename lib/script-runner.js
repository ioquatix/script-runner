/** @babel */

const ScriptRunnerProcess = require('./script-runner-process');
const ScriptRunnerView = require('./script-runner-view');

const ChildProcess = require('child_process');
const ShellEnvironment = require('shell-environment');

const Path = require('path');
const Shellwords = require('shellwords');
const {CompositeDisposable} = require('atom');

const SCRIPT_RUNNER_URI = 'script-runner://';

export default {
	config: {
		splitDirection: {
			type: 'string',
			default: 'bottom',
			enum: ['left', 'right', 'bottom']
		},

		scrollbackDistance: {
			type: 'number',
			default: 555
		},
		
		clearBeforeExecuting: {
			type: 'boolean',
			default: true
		},

		theme: {
			type: 'string',
			default: 'light',
			enum: [
				{value: 'light', description: "Light"},
				{value: 'dark', description: "Dark"}
			]
		},
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
		{path: '\\.sh$', command: 'bash'},
	],
	
	disposables: null,
	
	activate() {
		this.disposables = new CompositeDisposable();
		
		this.disposables.add(
			atom.workspace.addOpener((uri) => {
				if (uri.startsWith(SCRIPT_RUNNER_URI)) {
					return new ScriptRunnerView(uri);
				}
			})
		);
		
		// register commands
		this.disposables.add(
			atom.commands.add('atom-workspace', {
				'script-runner:run': event => this.run(),
				'script-runner:shell': event => this.runShell(),
			})
		);
	},
	
	deactivate() {
		this.disposables.dispose();
	},
	
	runShell() {
		const editor = atom.workspace.getActiveTextEditor();
		if (editor == null) { return; }

		const path = Path.dirname(editor.getPath());
		
		atom.workspace.open(`script-runner://shell`, {
			searchAllPanes: true
		}).then((view) => {
			view.setTitle('Shell');
			
			ShellEnvironment.loginEnvironment((error, environment) => {
				if (environment) {
					const cmd = environment['SHELL'];
					const args = Shellwords.split(cmd).concat("-l");
					
					ScriptRunnerProcess.spawn(view, args, path, environment);
				} else {
					throw new Error(error);
				}
			});
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
		
		atom.workspace.open(`script-runner://${path}`, {
			searchAllPanes: true
		}).then((view) => {
			view.setTitle(path);
			
			ShellEnvironment.loginEnvironment((error, environment) => {
				if (environment) {
					ScriptRunnerProcess.run(view, cmd, environment, editor);
				} else {
					throw new Error(error);
				}
			});
		});
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
};
