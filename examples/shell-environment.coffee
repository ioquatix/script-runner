#!/usr/bin/env coffee

ShellEnvironment = require 'shell-environment'

ShellEnvironment.loginEnvironment (error, environment) =>
    if environment
        console.log(environment)
    else
        console.log(error)