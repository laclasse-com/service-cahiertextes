#!/usr/bin/env rackup
# -*- coding: utf-8; mode: ruby -*-

require ::File.expand_path( '../config/init', __FILE__ )

require ::File.expand_path( '../api', __FILE__ )
require ::File.expand_path( '../web', __FILE__ )

# Compile à la volée les templates en fichiers javascripts
Dir.glob( 'public/app/views/*.html' )
   .each do |fichier|
  target = "#{fichier.gsub( /views/, 'js/templates' )}.js"
  template_name = fichier.gsub( %r{public/app/}, '' )
  template = File.read( fichier )

  STDERR.puts "generating #{target} from #{fichier}"
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
    target_file.write "angular.module( 'cahierDeTexteApp' )\n"
    target_file.write "  .run( [ '$templateCache',\n"
    target_file.write "    function( $templateCache ) {\n"
    target_file.write "      $templateCache.put( '#{template_name}',\n"
    target_file.write "                          '#{template}' ); "
    target_file.write '    } ] );'
  end
end

# Minifie les JS
bouteille = ''
Dir.glob( 'public/app/js/**/*.js' )
   .reject { |fichier| /min\.js$/.match fichier }
   .sort
   .each do |fichier|
  STDERR.puts "reading #{fichier}"

  bouteille << File.read( fichier )
end
File.open( './public/app/js/cdt.min.js', 'w' ) do |target_file|
  target_file.write( Uglifier.compile( bouteille ) )
end

use Rack::Rewrite do
  rewrite %r{^/logout/?$}, "#{APP_PATH}/logout"
  rewrite %r{^#{APP_PATH}(/app/(js|css|vendor)/.*(css|js|ttf|woff|html|png|jpg|jpeg|gif|svg)[?v=0-9a-zA-Z\-.]*$)}, '$1'
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
