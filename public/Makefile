all: clean minify

clean:
	-rm app/js/cdt.min.js

minify: app/js/cdt.min.js

app/js/cdt.min.js:
	uglifyjs -p 5 -c -m -o $@ $$(find app/js/{services,controllers,filters}/ -name \*.js)

.PHONY: all clean minify
