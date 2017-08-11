/** @babel */
/** @jsx Etch.dom */

const Etch = require('etch');
const {Emitter} = require('atom');
const Terminal = require('xterm');
Terminal.loadAddon('fit');

export default class ScriptRunnerView {
	static deserialize({title, output}) {
		const view = new ScriptRunnerView(title);
		
		return view;
	}
	
	constructor(title) {
		Etch.initialize(this);
		
		this.emitter = new Emitter;
		
		atom.commands.add(this.element, {
			'script-runner:copy': () => this.copyToClipboard(),
			'script-runner:paste': () => this.pasteToTerminal()
		});
		
		this.resizeObserver = new ResizeObserver(() => this.outputResized());
		this.resizeObserver.observe(this.element);
	
		this.setTitle(title);
		this.setupTerminal();
	}
	
	destroy() {
		this.resizeObserver.disconnect();
		
		if (this.terminal)
			this.terminal.destroy();
		
		Etch.destroy(this);
	}

	serialize() {
		return {
			deserializer: 'ScriptRunnerView',
			title: this.title,
			output: this.element.innerHTML
		};
	}
	
		render() {
		return (
			<script-runner-view attributes={{tabindex: 0}} />
		);
	}

	update() {
		return Etch.update(this);
	}
	
	copyToClipboard() {
		return atom.clipboard.write(this.terminal.getSelection());
	}

	pasteToTerminal() {
		return this.emitter.emit('data', atom.clipboard.read());
	}

	getIconName() {
		return 'terminal';
	}

	getTitle() {
		return `Script Runner: ${this.title}`;
	}

	setTitle(title) {
		return this.title = title;
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
			screenKeys: false,
			cursorBlink: true
		});
	
		this.terminal.on('resize', geometry => {
			return this.emitter.emit('resize', geometry);
		});
	
		this.terminal.on('data', data => {
			return this.emitter.emit('data', data);
		});
	
		this.terminal.on('key', (key, event) => {
			return this.emitter.emit('key', event);
		});
	
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
			
		this.terminal.open(this.element, true);
		
		return this.terminal.fit();
	}

	outputResized() {
		if (this.terminal)
			return this.terminal.fit();
	}

	focus() {
		if (this.terminal)
			return this.terminal.focus();
	}

	clear() {
		if (this.terminal)
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
