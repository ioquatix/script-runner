#!/usr/bin/env bash

trap '' INT

ruby ./test.rb

trap 'echo "Hello World"; exit 0' INT

ruby ./test.rb

kill -SIGINT $$

echo "Hello World"

sleep 20

echo "Exiting"

exit 10
