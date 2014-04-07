all: clean minify

clean:
	-rm app/scripts/app.min.js app/scripts/constants.min.js app/scripts/cdt.min.js app/styles/main.min.css

minify: app/scripts/app.min.js app/scripts/constants.min.js app/scripts/cdt.min.js app/styles/main.min.css

app/scripts/app.min.js:
	uglifyjs -p 5 -c -m -o $@ app/scripts/app.js

app/scripts/constants.min.js:
	uglifyjs -p 5 -c -m -o $@ app/scripts/constants.js

app/scripts/cdt.min.js:
	uglifyjs -p 5 -c -m -o $@ $$(find app/scripts/{services,controllers,directives}/ -name \*.js)

app/styles/main.min.css: app/styles/main.css
	uglifycss $^ > $@

.PHONY: all clean minify
