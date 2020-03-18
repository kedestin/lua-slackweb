# Lua-SlackWeb

A Lua module for Slack's Web API

## In this repository

    .
    ├── examples
    ├── Makefile
    ├── slackweb.lua
    └── src
        ├── requirements.txt
        ├── slackweb.py
        └── transliterate.py

 * `src/` contains the source code for the module generator
 * `examples/` shows example usage of the module
 * slack

 ## Building the Module

Generator targets python versions >= 3.5.2.

1. Install `src/requirements.txt` with pip
2. Run `make slackweb.lua`

## Usage

### Dependencies

`lua-slackweb` depends on [`lua-requests`](https://github.com/JakobGreen/lua-requests)

### Using the module

All the endpoints have analogously named functions in `lua-slackweb`

For example, if you wanted to invoke the [`chat.postMessage`](https://api.slack.com/methods/chat.postMessage) method you could do so as follows:

```lua
local sw = require 'slackweb'

token="YOURACCESSTOKEN" -- see docs/gettingstarted.md

sw.chat.postMessage{
    token=token,
    channel="CHANNELID", -- see examples/sendmessage.lua
    text="Hello Slack!"
}
```

#### Arguments

All `lua-slackweb` functions use the [named arguments](https://www.lua.org/pil/5.3.html) technique described in the Lua Manual. That is, each function expects a single table, in which method parameters are specified by name.

#### Return

All `lua-slackweb` functions return the body of the response.


#### Error Handling


##### Missing required parameters

`lua-slackweb` functions throw an error when a function is missing a required parameter

For example, invoking `chat.postMesssage` without specifying the token would produce an error similar to

```
lua: slackweb.lua:13: SlackWeb: missing required argument 'token'
```

##### Slack Error

If Slack determines that something went wrong, the response will contain the 
field `"ok": false`, and the error will be specified in the `error` field.

`lua-slackweb` will throw an error if that occurs.

For example, invoking `chat.postMessage` with an invalid token would produce an error similar to

```
lua: slackweb.lua:45: SlackWeb: SlackError: invalid_auth
```

