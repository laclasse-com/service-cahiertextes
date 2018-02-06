all: public/app/js/app.min.js

# find public/app/ts -type f -exec echo -n {}\  \;
public/app/js/app.js: public/app/ts/resources/etablissements.ts public/app/ts/resources/matchable.ts public/app/ts/resources/cours.ts public/app/ts/resources/salles.ts public/app/ts/resources/devoirs.ts public/app/ts/resources/creneaux.ts public/app/ts/directives/cartable.ts public/app/ts/directives/file_model.ts public/app/ts/http_interceptors.ts public/app/ts/routes.ts public/app/ts/controllers/PopupDisplayCtrl.ts public/app/ts/controllers/AssignementsCtrl.ts public/app/ts/controllers/DashboardTeacherCtrl.ts public/app/ts/controllers/HeaderCtrl.ts public/app/ts/controllers/FooterCtrl.ts public/app/ts/controllers/PopupEditionCtrl.ts public/app/ts/controllers/TextBookCtrl.ts public/app/ts/controllers/ImportCtrl.ts public/app/ts/controllers/IndexCtrl.ts public/app/ts/controllers/DashboardTeachersCtrl.ts public/app/ts/defaults.ts public/app/ts/services/log.ts public/app/ts/services/Utils.ts public/app/ts/services/PopupsCreneau.ts public/app/ts/services/Redirection.ts public/app/ts/services/currentUser.ts public/app/ts/services/API.ts public/app/ts/services/FileUpload.ts public/app/ts/services/Annuaire.ts public/app/ts/services/Documents.ts public/app/ts/app.ts public/app/ts/components/displayDevoir.ts public/app/ts/components/displaySequencePedagogique.ts public/app/ts/components/switchDevoir.ts public/app/ts/config.ts
	-./public/app/node_modules/.bin/tsc --project ./public/app/tsconfig.json

public/app/js/app.min.js: public/app/js/app.js
	./public/app/node_modules/.bin/google-closure-compiler-js $^ > $@

pull-deps:
	bundle install --path .bundle
	cd public/app; npm install

clean:
	-rm public/app/js/app.min.js public/app/js/app.js

clean-all: clean
	-rm -fr .bundle/ruby/
	-rm -fr public/app/node_modules

# DB

db-migrate:
	bundle exec sequel ./config/database.yml --migrate-directory ./migrations

# Pry
pry:
	RACK_ENV=development bundle exec ruby -e "require './app'; pry.binding"
