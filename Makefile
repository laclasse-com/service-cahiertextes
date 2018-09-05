pull-deps:
	bundle install --path .bundle

clean-all: clean
	-rm -fr .bundle/ruby/

# DB
db-migrate:
	bundle exec sequel ./config/database.yml --migrate-directory ./migrations

# Pry
pry:
	RACK_ENV=development bundle exec ruby -e "require './app'; pry.binding"
