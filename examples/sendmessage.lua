#!/usr/bin/env lua

-- Use pl.pretty to print if installed
local installed, pl = pcall(function() return require("pl.pretty") end)
if installed then pprint = pl.dump else pprint = print end

package.path = package.path .. ";../?.lua" -- Add slackweb.lua to path
local sw = require 'slackweb'

local token = "" -- insert token here


-- Get the Slack ID given the name of the channel.
-- Returns nil if not found
function channelID(name)
    local channellist = sw.conversations.list{token = token}.channels
    for i, conversation in ipairs(channellist) do
        if conversation.name == name then return conversation.id end
    end
    return nil
end

pprint(sw.chat.postMessage{
    token = token,
    channel = channelID("general"),
    text = "I am a test message",
    attachments = {{text = "And here’s an attachment!"}}
}.message)

