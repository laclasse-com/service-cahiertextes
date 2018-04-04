all: public/js/app.min.js

# find public/ts -type f -exec echo -n {}\  \;
public/js/app.js: public/ts/resources/etablissements.ts public/ts/resources/matchable.ts public/ts/resources/cours.ts public/ts/resources/salles.ts public/ts/resources/devoirs.ts public/ts/resources/creneaux.ts public/ts/directives/cartable.ts public/ts/directives/file_model.ts public/ts/http_interceptors.ts public/ts/routes.ts public/ts/controllers/PopupDisplayCtrl.ts public/ts/controllers/AssignementsCtrl.ts public/ts/controllers/DashboardTeacherCtrl.ts public/ts/controllers/HeaderCtrl.ts public/ts/controllers/FooterCtrl.ts public/ts/controllers/PopupEditionCtrl.ts public/ts/controllers/TextBookCtrl.ts public/ts/controllers/ImportCtrl.ts public/ts/controllers/IndexCtrl.ts public/ts/controllers/DashboardTeachersCtrl.ts public/ts/defaults.ts public/ts/services/log.ts public/ts/services/Utils.ts public/ts/services/PopupsCreneau.ts public/ts/services/Redirection.ts public/ts/services/currentUser.ts public/ts/services/API.ts public/ts/services/FileUpload.ts public/ts/services/Annuaire.ts public/ts/services/Documents.ts public/ts/app.ts public/ts/components/displayDevoir.ts public/ts/components/displaySequencePedagogique.ts public/ts/components/switchDevoir.ts public/ts/config.ts
	-./public/node_modules/.bin/tsc --project ./public/tsconfig.json

public/js/app.min.js: public/js/app.js
	./public/node_modules/.bin/google-closure-compiler-js $^ > $@

pull-deps:
	bundle install --path .bundle
	cd public/app; npm install

clean:
	-rm public/js/app.min.js public/js/app.js

clean-all: clean
	-rm -fr .bundle/ruby/
	-rm -fr public/node_modules

# DB

db-migrate:
	bundle exec sequel ./config/database.yml --migrate-directory ./migrations

# Pry
pry:
	RACK_ENV=development bundle exec ruby -e "require './app'; pry.binding"
