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
    STDERR.puts 'Sassification of vendor CSS'
    uglified = Sass.compile( [ 'public/app/vendor/fullcalendar/dist/fullcalendar.css',
                               'public/app/vendor/angular-loading-bar/build/loading-bar.min.css',
                               'public/app/vendor/nvd3/nv.d3.min.css',
                               'public/app/vendor/ng-switcher/dist/ng-switcher.min.css',
                               'public/app/vendor/ng-color-picker/color-picker.css',
                               'public/app/vendor/sweetalert/dist/sweetalert.css',
                               'public/app/vendor/angular-toastr/dist/angular-toastr.css',
                               'public/app/vendor/laclasse-common-client/css/bootstrap-theme.css' ]
                             .map { |fichier| File.read( fichier ) }.join,
                             syntax: :scss,
                             style: :compressed )
    File.open( './public/app/vendor/vendor.min.css', 'w' )
      .write( uglified )

    STDERR.puts 'Sassification of application CSS'
    uglified = Sass.compile( [ 'public/app/css/main.scss' ]
                             .map { |fichier| File.read( fichier ) }.join,
                             syntax: :scss,
                             style: :compressed )
    File.open( './public/app/css/cdt.min.css', 'w' )
      .write( uglified )
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

    STDERR.puts 'Uglification of vendor Javascript'
    # rubocop:disable Metrics/LineLength
    uglified, source_map = Uglify.those_files_with_map( [ 'public/app/vendor/jquery/dist/jquery.js',
                                                          'public/app/vendor/underscore/underscore.js',
                                                          'public/app/vendor/moment/min/moment-with-locales.js',
                                                          'public/app/vendor/moment-timezone/moment-timezone.js',
                                                          'public/app/vendor/ng-file-upload/angular-file-upload-shim.js',
                                                          'public/app/vendor/sweetalert/dist/sweetalert.min.js',
                                                          'public/app/vendor/rangy/rangy-core.js',
                                                          'public/app/vendor/rangy/rangy-classapplier.js',
                                                          'public/app/vendor/rangy/rangy-selectionsaverestore.js',
                                                          'public/app/vendor/rangy/rangy-serializer.js',
                                                          'public/app/vendor/angular/angular.js',
                                                          'public/app/vendor/angular-touch/angular-touch.js',
                                                          'public/app/vendor/angular-animate/angular-animate.js',
                                                          'public/app/vendor/angular-bootstrap-checkbox/angular-bootstrap-checkbox.js',
                                                          'public/app/vendor/angular-bootstrap/ui-bootstrap-tpls.js',
                                                          'public/app/vendor/angular-cookies/angular-cookies.js',
                                                          'public/app/vendor/angular-i18n/angular-locale_fr-fr.js',
                                                          'public/app/vendor/angular-loading-bar/build/loading-bar.js',
                                                          'public/app/vendor/angular-moment/angular-moment.js',
                                                          'public/app/vendor/angular-resource/angular-resource.js',
                                                          'public/app/vendor/angular-sanitize/angular-sanitize.js',
                                                          'public/app/vendor/angular-ui-calendar/src/calendar.js',
                                                          'public/app/vendor/angular-ui-router/release/angular-ui-router.js',
                                                          'public/app/vendor/angularjs-nvd3-directives/dist/angularjs-nvd3-directives.js',
                                                          'public/app/vendor/d3/d3.js',
                                                          'public/app/vendor/fullcalendar/dist/fullcalendar.js',
                                                          'public/app/vendor/fullcalendar/dist/lang-all.js',
                                                          'public/app/vendor/ng-color-picker/color-picker.js',
                                                          'public/app/vendor/ng-file-upload/angular-file-upload.js',
                                                          'public/app/vendor/ng-switcher/dist/ng-switcher.js',
                                                          'public/app/vendor/nvd3/nv.d3.js',
                                                          'public/app/vendor/textAngular/src/textAngular-sanitize.js',
                                                          'public/app/vendor/textAngular/src/textAngularSetup.js',
                                                          'public/app/vendor/textAngular/src/textAngular.js',
                                                          'public/app/vendor/angular-toastr/dist/angular-toastr.tpls.js' ] )
    # rubocop:enable Metrics/LineLength
    File.open( './public/app/vendor/vendor.min.js', 'w' )
      .write( uglified )
    File.open( './public/app/vendor/vendor.min.js.map', 'w' )
      .write( source_map )
  end
end
