# lua-slack generator

A collection of python scripts that auto-generate a (badly-formatted) lua 
module for slack

## slackweb.py

Parses every endpoint specified on https://api.slack.com/methods and outputs
a json object that describes each method.

## transliterate.py

Given the output from slackweb.py, generates a lua module that facilitates 
using the Slack Web API

