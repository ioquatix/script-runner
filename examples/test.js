
var child_process = require('child_process')

console.log("Hello World")

//process.on('INT', function() {})

var child = child_process.spawn('./test.rb')

console.log("pid", child.pid)

child.on('exit', function(code, signal) {
	console.log(child.stdout.read().toString('utf8'))
	console.log('exit', code, signal)
})

setTimeout(function() {
  console.log('Finished');
}, 5000);

// process.exit(10)
