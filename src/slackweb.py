#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import json
from collections import defaultdict
import progressbar


def getSoup(html):
    return BeautifulSoup(html, features="html.parser")


def getFacts(methodsoup):
    """ Returns some metadata (called Facts in documentation) about endpoint
    """
    toReturn = {
        x.select("th")[0].text.rstrip(':'): x.select("td")[0].text.rstrip(':')
        for x in methodsoup.select("#facts + table > tr")
    }

    # Remove permission info, since it isn't used and is weirdly formatted
    toReturn.pop("Works with", None)
    # Turn content types into a list
    toReturn["Accepted content types"] = toReturn["Accepted content types"
                                                 ].split(", ")
    return toReturn


def getArgs(methodsoup):
    """ Returns a list of arguments for an API endpoint
    """
    return [
        {
            "name": x.select("[name^=arg]")[0].text,
            "required": x.select(".arg_required") != []
        } for x in methodsoup.select(".method_argument > .arg_title")
    ]


def getMethodURLs():
    """ Returns a list of urls to each API endpoint's documentation page
    """
    # Load the page that lists all the API endpoints
    soup = getSoup(requests.get("https://api.slack.com/methods").content)
    return [
        "https://api.slack.com" + a["href"]
        for a in soup.select("tr > td > a.block")
    ]


def main():
    # https://gist.github.com/hrldcpr/2012250
    def tree():
        """ Generates a tree
        """
        return defaultdict(tree)

    root = tree()

    def tree_insert(path, payload, curr=root):
        """ Insert payload into tree, at specified path
        """
        if len(path) == 0:
            return payload
        curr[path[0]] = tree_insert(path[1:], payload, curr[path[0]])
        return curr

    for url in progressbar.progressbar(getMethodURLs()):
        soup = getSoup(requests.get(url).content)
        tree_insert(
            url.split("/")[-1].split("."),
            dict(metadata=getFacts(soup), args=getArgs(soup))
        )
    return root


if __name__ == "__main__":
    with open("slackweb.json", "w") as f:
        json.dump(main(), f, indent=4)
