#!/usr/bin/env python3
import json
import argparse
import slackweb
import io
INDENT = "    "

PREAMBLE = """local BASEURL = "https://slack.com/api/"

function required(rrs)
    return function(args)
        for _, r in ipairs(rrs) do
            if args[r] == nil then
                error("SlackWeb: missing required argument '" .. r .. "'")
            end
        end
        return args
    end
end

function get(url, contenttype, payloadfunc)
        return sendrequest(
                function (args) return requests.get(args) end,
                url, contenttype, payloadfunc)
end

function post(url, contenttype, payloadfunc)
        return sendrequest(
                function (args) return requests.post(args) end,
                url, contenttype, payloadfunc)
end

function sendrequest(requestfunc, url, contenttype, payloadfunc)
    local headers = {['Content-Type'] = contenttype}
    local absurl = BASEURL .. url
    local tosend = {absurl, headers = headers}
    local payload_location = contenttype ~= "application/json" and "params" or
                                 "data"
    return function(args)
        tosend[payload_location] = payloadfunc(args)
        if tosend[payload_location].token ~= nil then
            tosend.headers.Authorization =
                "Bearer " .. tosend[payload_location].token
            tosend[payload_location].token = nil
        end
        response = requestfunc(tosend).json()
        if response.ok ~= true then
            error("SlackWeb: SlackError: " .. response.error)
        end
        return response
    end
end
"""


def isFunction(node):
    return set(node.keys()) == set(["metadata", "args"])


class Luafier():
    def __init__(self, slackmethods=None, output=None):
        self.output = io.StringIO() if output is None else output
        if slackmethods is not None:
            self.generate(slackmethods)

    def __print(self, *args, **kwargs):
        print(file=self.output, *args, **kwargs)

    def generate(self, node):
        #  Add dependencies
        self.__print(
            '\n'.join(
                [
                    "local requests = require('requests')",
                    "local mime = {json= 'application/json', urlenc='application/x-www-form-urlencoded'}"
                ]
            ),
            end="\n\n"
        )
        # Any needed functions
        self.__print(PREAMBLE, end="\n\n")

        # Walk the method tree, and output lua code
        self.genClass(node)

        # Return exported functions
        self.__print("return SlackWeb")

    def genFunction(self, node, prefix="SlackWeb"):
        httpmethod = node["metadata"]["Preferred HTTP method"]
        encoding = "mime.json" if "application/json" in node["metadata"][
            "Accepted content types"] else "mime.urlenc"

        # Check that required args are present, and return args when called
        requiredParams = "required{" + ", ".join(
            ["\"" + a["name"] + "\"" for a in node["args"] if a["required"]]
        ) + "}"

        # I only added syntactic sugar for post and get
        assert (httpmethod == "POST" or httpmethod == "GET")

        # Send the arguments with the appropriate http method and contenttype
        sendRequest = ''.join(
            [
                "get" if httpmethod == "GET" else "post", "(\"",
                node["metadata"]["Method URL"].split("/")[-1], "\", ",
                encoding, ", ", requiredParams, ")"
            ]
        )

        # Output to file
        self.__print(prefix.split(".")[-1] + " = " + sendRequest + ",")

    def genClass(self, node, prefix="SlackWeb"):
        methods = (x for x in node.keys() if isFunction(node[x]))
        classes = (x for x in node.keys() if not isFunction(node[x]))

        # Generate class, and embed class methods into declaration
        self.__print(prefix + " = {", end="")
        for x in methods:
            self.genFunction(node[x], '.'.join([prefix, x]))
        self.__print("}\n")

        # Generate subclasses
        for x in classes:
            self.genClass(node[x], '.'.join([prefix, x]))

    def dumps(self):
        return self.output.getvalue()


def main(slackmethods, output=None):
    if output is None:
        print(Luafier(slackmethods).dumps())
    else:
        with open(output, "w") as f:
            Luafier(slackmethods, output=f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-o",
        "--output",
        help="Path to file where output will be dumped",
        required=False,
        default=None
    )
    parser.add_argument(
        "--local",
        help="Path to slackweb.json (don't fetch from web)",
        required=False,
        default=None
    )
    args = parser.parse_args()

    if args.local != None:
        with open(args.local) as f:
            main(slackmethods=json.load(f), output=args.output)
    else:
        main(slackmethods=slackweb.main(), output=args.output)