#!/usr/bin/env bash

echo PATH: $PATH
echo PID: $$

trap '' INT

ruby ./test.rb

trap 'echo "Hello World"; exit 0' INT

ruby ./test.rb

kill -SIGTERM $$
#echo "Hello World"
#sleep 20

echo "Exiting"
exit 1
