/** @jsx Etch.dom */

import Etch from 'etch';
import {Emitter} from 'atom';
import ResizeObserver from 'resize-observer-polyfill';

import {Terminal} from 'xterm';
import {FitAddon} from 'xterm-addon-fit';

export default class ScriptRunnerView {
	static deserialize({uri, title, state}) {
		const view = new ScriptRunnerView(uri, title);
		
		if (state) {
			view.terminal.setState(state);
		}
		
		return view;
	}
	
	constructor(uri, title) {
		Etch.initialize(this);
		console.log("element", this.element);
		
		this.uri = uri;
		
		this.emitter = new Emitter;
		
		atom.commands.add(this.element, {
			'script-runner:copy': () => this.copyToClipboard(),
			'script-runner:paste': () => this.pasteToTerminal(),
			'script-runner:clear': () => this.clear(),
			'script-runner:interrupt': event => this.kill('SIGINT'),
			'script-runner:terminate': event => this.kill('SIGTERM'),
			'script-runner:kill': event => this.kill('SIGKILL'),
		});
		
		if (title == null)
			this.title = uri;
		else
			this.title = title;
		
		this.setupTerminal();
		
		this.resizeObserver = new ResizeObserver(() => this.outputResized());
		this.resizeObserver.observe(this.element);
	}
	
	destroy() {
		this.resizeObserver.disconnect();
		
		if (this.process)
			this.process.destroy();
		
		if (this.terminal)
			this.terminal.destroy();
		
		Etch.destroy(this);
	}

	serialize() {
		return {
			deserializer: 'ScriptRunnerView',
			uri: this.uri,
			title: this.title,
			//state: this.terminal.getState(),
		};
	}
	
	render() {
		return (
			<script-runner-view attributes={{tabindex: 0}} />
		);
	}

	update(props, children) {
		return Etch.update(this);
	}
	
	copyToClipboard() {
		return atom.clipboard.write(this.terminal.getSelection());
	}

	pasteToTerminal() {
		return this.emitter.emit('paste', atom.clipboard.read());
	}

	getURI() {
		return this.uri;
	}

	getIconName() {
		return 'terminal';
	}

	getTitle() {
		return `Script Runner: ${this.title}`;
	}

	getDefaultLocation() {
		return atom.config.get('script-runner.splitDirection') || 'bottom';
	}
	
	setTitle(title) {
		this.title = title;
		
		this.emitter.emit("did-change-title", this.getTitle());
	}
	
	// Invoked by the atom workspace to monitor the view's title:
	onDidChangeTitle(callback) {
		return this.emitter.on('did-change-title', callback)
	}
	
	setTheme(theme) {
		this.theme = theme;
		return this.element.setAttribute('data-theme', theme);
	}

	setupTerminal() {
		this.terminal = new Terminal({
			rows: 40,
			cols: 80,
			scrollback: atom.config.get('script-runner.scrollback'),
			useStyle: false,
			cursorBlink: true
		});
		
		this.fitAddon = new FitAddon();
		this.terminal.loadAddon(this.fitAddon);
		
		this.element.addEventListener('focus', () => this.terminal.focus());
		
		var style = '';
		const editor = atom.config.settings.editor;
		
		if (editor) {
			if (editor.fontSize)
				style += 'font-size:' + editor.fontSize + 'px;';
			if (editor.fontFamily)
				style += 'font-family:' + editor.fontFamily + ';';
			if (editor.lineHeight)
				style += 'line-height:' + editor.lineHeight + ';';
			
			this.element.setAttribute('style', style);
		}
	}

	outputResized() {
		if (!this.terminal.element) {
			this.terminal.open(this.element, true);
		}
		
		this.fitAddon.fit();
	}

	kill(signal) {
		if (this.process)
			this.process.kill(signal);
	}

	focus() {
		return this.terminal.focus();
	}

	clear() {
		return this.terminal.clear();
	}

	on(event, callback) {
		return this.emitter.on(event, callback);
	}

	append(text, className) {
		return this.terminal.write(text);
	}

	log(text) {
		return this.terminal.write(text + "\r\n");
	}
};

atom.deserializers.add(ScriptRunnerView);
