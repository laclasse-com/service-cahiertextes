# coding: utf-8

ENV['RACK_ENV'] = 'development'
namespace :preprocess_assets do
  task :load_config do
    require 'rubygems'
    require 'bundler'

    Bundler.require( :default, ENV['RACK_ENV'].to_sym )     # require tout les gems définis dans Gemfile

    require_relative '../lib/uglify'
  end

  desc 'Everything'
  task all: [ :templates, :js, :css ]

  desc 'For development deployement'
  task development: [ :templates, :css ]

  desc 'For production deployement'
  task production: [ :templates, :js, :css ]

  desc 'Javascriptify templates'
  task templates: :load_config do
    STDERR.puts 'Compilation of angular templates into javascript files'
    Dir.glob( 'public/app/views/*.html' )
       .each do |fichier|
      target = "#{fichier.gsub( /views/, 'js/templates' )}.js"
      template_name = fichier.gsub( %r{public/app/}, '' )
      template = File.read( fichier )

      # un peu de travail d'escaping sur le contenu HTML
      # suppression des retour à la ligne
      template.tr!( "\n", '' )
      # escaping des apostrophes
      template.gsub!(/'/) { %q(\') }

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
  end

  desc 'Minify CSS using Sass'
  task css: :load_config do
    STDERR.puts 'Sassification of node_modules CSS'
    uglified = Sass.compile( [ 'public/app/node_modules/fullcalendar/dist/fullcalendar.css',
                               'public/app/node_modules/angular-loading-bar/build/loading-bar.min.css',
                               'public/app/node_modules/nvd3/build/nv.d3.min.css',
                               'public/app/node_modules/angular-ui-switch/angular-ui-switch.min.css',
                               'public/app/node_modules/ng-color-picker/color-picker.css',
                               'public/app/node_modules/sweetalert/dist/sweetalert.css',
                               'public/app/node_modules/angular-toastr/dist/angular-toastr.css',
                               'public/app/node_modules/laclasse-common-client/css/main.css',
                               'public/app/node_modules/laclasse-common-client/css/bootstrap-theme.css',
                               'public/app/node_modules/ui-select/dist/select.css' ]
                               .map { |fichier| File.read( fichier ) }.join,
                             syntax: :scss,
                             style: :compressed )
    File.open( './public/app/node_modules/node_modules.min.css', 'w' ).write( uglified )

    STDERR.puts 'Sassification of application CSS'
    uglified = Sass.compile( [ 'public/app/css/main.scss',
                               'public/app/css/other_media.css' ]
                               .map { |fichier| File.read( fichier ) }.join,
                             syntax: :scss,
                             style: :compressed )
    File.open( './public/app/css/cdt.min.css', 'w' ).write( uglified )
  end

  desc 'Minify JS using Uglifier'
  task js: :load_config do
    STDERR.puts 'Uglification of application Javascript'
    uglified, source_map = Uglify.those_files_with_map( Dir.glob( 'public/app/js/**/*.js' )
                                                           .reject { |fichier| /min\.js$/.match fichier }
                                                           .sort )
    File.open( './public/app/js/cdt.min.js', 'w' )
        .write( uglified )
    File.open( './public/app/js/cdt.min.js.map', 'w' )
        .write( source_map )

    STDERR.puts 'Uglification of node_modules Javascript'
    uglified, source_map = Uglify.those_files_with_map( [ 'public/app/node_modules/jquery/dist/jquery.js',
                                                          'public/app/node_modules/underscore/underscore.js',
                                                          'public/app/node_modules/moment/min/moment-with-locales.js',
                                                          'public/app/node_modules/moment-timezone/moment-timezone.js',
                                                          'public/app/node_modules/sweetalert/dist/sweetalert.min.js',
                                                          'public/app/node_modules/rangy/lib/rangy-core.js',
                                                          'public/app/node_modules/rangy/lib/rangy-classapplier.js',
                                                          'public/app/node_modules/rangy/lib/rangy-selectionsaverestore.js',
                                                          'public/app/node_modules/rangy/lib/rangy-serializer.js',
                                                          'public/app/node_modules/angular/angular.js',
                                                          'public/app/node_modules/angular-touch/angular-touch.js',
                                                          'public/app/node_modules/angular-animate/angular-animate.js',
                                                          'public/app/node_modules/angular-bootstrap-checkbox/angular-bootstrap-checkbox.js',
                                                          'public/app/node_modules/angular-ui-bootstrap/dist/ui-bootstrap-tpls.js',
                                                          'public/app/node_modules/angular-cookies/angular-cookies.js',
                                                          'public/app/node_modules/angular-i18n/angular-locale_fr-fr.js',
                                                          'public/app/node_modules/angular-loading-bar/build/loading-bar.js',
                                                          'public/app/node_modules/angular-moment/angular-moment.js',
                                                          'public/app/node_modules/angular-resource/angular-resource.js',
                                                          'public/app/node_modules/angular-sanitize/angular-sanitize.js',
                                                          'public/app/node_modules/angular-ui-calendar/src/calendar.js',
                                                          'public/app/node_modules/angular-ui-router/release/angular-ui-router.js',
                                                          'public/app/node_modules/angular-nvd3/dist/angular-nvd3.js',
                                                          'public/app/node_modules/d3/d3.js',
                                                          'public/app/node_modules/fullcalendar/dist/fullcalendar.js',
                                                          'public/app/node_modules/fullcalendar/dist/locale-all.js',
                                                          'public/app/node_modules/ng-color-picker/color-picker.js',
                                                          'public/app/node_modules/angular-ui-switch/angular-ui-switch.js',
                                                          'public/app/node_modules/nvd3/build/nv.d3.js',
                                                          'public/app/node_modules/textangular/src/textAngular-sanitize.js',
                                                          'public/app/node_modules/textangular/src/textAngularSetup.js',
                                                          'public/app/node_modules/textangular/dist/textAngular.js',
                                                          'public/app/node_modules/angular-toastr/dist/angular-toastr.tpls.js',
                                                          'public/app/node_modules/ui-select/dist/select.js' ] )
    File.open( './public/app/node_modules/node_modules.min.js', 'w' )
        .write( uglified )
    File.open( './public/app/node_modules/node_modules.min.js.map', 'w' )
        .write( source_map )
  end
end
