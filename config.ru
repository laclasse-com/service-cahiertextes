#!/usr/bin/env rackup
# -*- coding: utf-8; mode: ruby -*-

require ::File.expand_path( '../config/init', __FILE__ )

require ::File.expand_path( '../api', __FILE__ )
require ::File.expand_path( '../web', __FILE__ )

require ::File.expand_path( '../lib/uglify', __FILE__ )

# Compile à la volée les templates en fichiers javascripts
STDERR.puts "Compilation of angular templates into javascript files"
Dir.glob( 'public/app/views/*.html' )
   .each do |fichier|
  target = "#{fichier.gsub( /views/, 'js/templates' )}.js"
  template_name = fichier.gsub( %r{public/app/}, '' )
  template = File.read( fichier )

  # un peu de travail d'escaping sur le contenu HTML
  # suppression des retour à la ligne
  template.tr!( "\n", '' )
  # escaping des apostrophes
  template.gsub!(/'/){ %q(\') }

  # élimination du précédent template JS si besoin
  File.delete( target ) if File.exist?( target )

  # génération du template JS
  File.open( target, 'w' ) do |target_file|
    target_file.write "'use strict';\n"
    target_file.write "angular.module( 'cahierDeTextesClientApp' )\n"
    target_file.write "  .run( [ '$templateCache',\n"
    target_file.write "    function( $templateCache ) {\n"
    target_file.write "      $templateCache.put( '#{template_name}',\n"
    target_file.write "                          '#{template}' ); "
    target_file.write '    } ] );'
  end
end

if ENV['RACK_ENV'] == 'production'
  # Minifie les CSS
  STDERR.puts 'Sassification of vendor CSS'
  uglified = Sass.compile( [ 'public/app/vendor/fullcalendar/fullcalendar.css',
                             'public/app/vendor/angular-loading-bar/build/loading-bar.min.css',
                             'public/app/vendor/nvd3/nv.d3.min.css',
                             'public/app/vendor/angular-tree-control/css/tree-control.css',
                             'public/app/vendor/angular-tree-control/css/tree-control-attribute.css',
                             'public/app/vendor/ng-switcher/dist/ng-switcher.min.css',
                             'public/app/vendor/ng-color-picker/color-picker.css',
                             'public/app/vendor/sweetalert/lib/sweet-alert.css' ]
                           .map { |fichier| File.read( fichier ) }.join,
                           syntax: :scss,
                           style: :compressed )
  File.open( './public/app/vendor/vendor.min.css', 'w' )
      .write( uglified )

  STDERR.puts 'Sassification of application CSS'
  uglified = Sass.compile( [ 'public/app/css/bootstrap-theme.css',
                             'public/app/css/main.css' ]
                           .map { |fichier| File.read( fichier ) }.join,
                           syntax: :scss,
                           style: :compressed )
  File.open( './public/app/css/cdt.min.css', 'w' )
      .write( uglified )

  # Minifie les JS
  STDERR.puts 'Uglification of application Javascript'
  uglified, source_map = Uglify.those_files_with_map( Dir.glob( 'public/app/js/**/*.js' )
                                                         .reject { |fichier| /min\.js$/.match fichier }
                                                         .sort )
  File.open( './public/app/js/cdt.min.js', 'w' )
      .write( uglified )
  File.open( './public/app/js/cdt.min.js.map', 'w' )
      .write( source_map )

  STDERR.puts 'Uglification of vendor Javascript'
  uglified, source_map = Uglify.those_files_with_map( [ 'public/app/vendor/jquery/dist/jquery.js',
                                                        'public/app/vendor/jquery-ui/ui/jquery-ui.js',
                                                        'public/app/vendor/underscore/underscore.js',
                                                        'public/app/vendor/moment/min/moment-with-locales.js',
                                                        'public/app/vendor/ng-file-upload/angular-file-upload-shim.js',
                                                        'public/app/vendor/sweetalert/lib/sweet-alert.js',
                                                        'public/app/vendor/angular/angular.js',
                                                        'public/app/vendor/angular-animate/angular-animate.js',
                                                        'public/app/vendor/angular-bootstrap-checkbox/angular-bootstrap-checkbox.js',
                                                        'public/app/vendor/angular-bootstrap/ui-bootstrap-tpls.js',
                                                        'public/app/vendor/angular-cookies/angular-cookies.js',
                                                        'public/app/vendor/angular-i18n/angular-locale_fr-fr.js',
                                                        'public/app/vendor/angular-loading-bar/build/loading-bar.js',
                                                        'public/app/vendor/angular-moment/angular-moment.js',
                                                        'public/app/vendor/angular-resource/angular-resource.js',
                                                        'public/app/vendor/angular-sanitize/angular-sanitize.js',
                                                        'public/app/vendor/angular-tree-control/angular-tree-control.js',
                                                        'public/app/vendor/angular-ui-calendar/src/calendar.js',
                                                        'public/app/vendor/angular-ui-router/release/angular-ui-router.js',
                                                        'public/app/vendor/angularjs-nvd3-directives/dist/angularjs-nvd3-directives.js',
                                                        'public/app/vendor/d3/d3.js',
                                                        'public/app/vendor/fullcalendar/fullcalendar.js',
                                                        'public/app/vendor/ng-color-picker/color-picker.js',
                                                        'public/app/vendor/ng-file-upload/angular-file-upload.js',
                                                        'public/app/vendor/ng-switcher/dist/ng-switcher.js',
                                                        'public/app/vendor/nvd3/nv.d3.js',
                                                        'public/app/vendor/textAngular/src/textAngular-sanitize.js',
                                                        'public/app/vendor/textAngular/src/textAngularSetup.js',
                                                        'public/app/vendor/textAngular/src/textAngular.js' ] )
  File.open( './public/app/vendor/vendor.min.js', 'w' )
      .write( uglified )
  File.open( './public/app/vendor/vendor.min.js.map', 'w' )
      .write( source_map )
end

use Rack::Rewrite do
  rewrite %r{^/logout/?$}, "#{APP_PATH}/logout"
  rewrite %r{^#{APP_PATH}(/app/(js|css|vendor)/.*(map|css|js|ttf|woff|html|png|jpg|jpeg|gif|svg)[?v=0-9a-zA-Z\-.]*$)}, '$1'
end

use Rack::Session::Cookie,
    key: 'rack.session',
    path: APP_PATH,
    expire_after: 3600, # 1 heure en secondes
    secret: SESSION_KEY

use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = "#{APP_PATH}/auth"
  end
  provider :cas, CASAUTH::CONFIG
end

STDERR.puts "#{ENV['RACK_ENV']} environment"

map "#{APP_PATH}/api" do
  run CahierDeTextesAPI::API
end

run CahierDeTextesAPI::Web
