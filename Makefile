slackweb.lua: slackweb.json
	src/transliterate.py -o slackweb.lua --local slackweb.json

slackweb.json:
	src/slackweb.py

clean:
	rm slackweb.json slackweb.lua