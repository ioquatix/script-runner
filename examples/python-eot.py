#!/usr/bin/env python

import subprocess, sys

def python_eot():
    p = subprocess.Popen(sys.executable, stdin=subprocess.PIPE)

    # Write some code to python process:
    p.stdin.write("print('Hello World')\n".encode())

    # Send EOT marker:
    p.stdin.write("\n\x04\n".encode())
    p.stdin.flush()

    # OR: close input
    #p.stdin.close()

    p.wait()

def ruby_eot():
    p = subprocess.Popen("ruby", stdin=subprocess.PIPE)

    # Write some code to python process:
    p.stdin.write("print('Hello World')\n".encode())

    # Send EOT marker:
    p.stdin.write("\n\x04\n".encode())
    p.stdin.flush()

    # OR: close input
    #p.stdin.close()

    p.wait()

def bash_eot():
    p = subprocess.Popen("bash", stdin=subprocess.PIPE)

    # Write some code to python process:
    p.stdin.write("echo Hello World\n".encode())

    # Send EOT marker:
    p.stdin.write("\n\x04\n".encode())
    p.stdin.flush()

    # OR: close input
    #p.stdin.close()

    p.wait()

bash_eot()

