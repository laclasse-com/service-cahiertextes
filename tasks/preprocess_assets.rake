# coding: utf-8

namespace :preprocess_assets do
  task :load_config do
    require 'rubygems'
    require 'bundler'

    Bundler.require( :default, :development ) # require tout les gems définis dans Gemfile

    require_relative '../config/options'
    COMPILED_FILE = "#{APP_ROOT}/public/app/js/app.js".freeze
    MINIFIED_FILE = "#{APP_ROOT}/public/app/js/app.min.js".freeze
  end

  desc 'Clean away compiled files'
  task clean: [:load_config] do
    puts `[ -e #{COMPILED_FILE} ] && rm #{COMPILED_FILE}`
    puts `[ -e #{MINIFIED_FILE} ] && rm #{MINIFIED_FILE}`
  end

  desc 'Minify CSS using Sass'
  task css: [:load_config] do
    STDERR.puts 'Sassification of node_modules CSS'
    uglified = Sass.compile( [ 'public/app/node_modules/fullcalendar/dist/fullcalendar.css',
                               'public/app/node_modules/angular-loading-bar/build/loading-bar.min.css',
                               'public/app/node_modules/nvd3/build/nv.d3.min.css',
                               'public/app/node_modules/angular-ui-switch/angular-ui-switch.min.css',
                               'public/app/node_modules/ng-color-picker/color-picker.css',
                               'public/app/node_modules/sweetalert2/dist/sweetalert2.css',
                               'public/app/node_modules/angular-toastr/dist/angular-toastr.css',
                               'public/app/node_modules/laclasse-common-client/css/main.css',
                               'public/app/node_modules/laclasse-common-client/css/bootstrap-theme.css',
                               'public/app/node_modules/ui-select/dist/select.css' ]
                               .map { |fichier| File.read( fichier ) }.join,
                             syntax: :scss,
                             style: :compressed )
    File.open( './public/app/node_modules/node_modules.min.css', 'w' )
        .write( uglified )

    STDERR.puts 'Sassification of application CSS'
    uglified = Sass.compile( [ 'public/app/css/main.scss' ]
                               .map { |fichier| File.read( fichier ) }.join,
                             syntax: :scss,
                             style: :compressed )
    File.open( './public/app/css/portail.min.css', 'w' )
        .write( uglified )
  end

  desc 'Compile typescript files'
  task ts2js: [:load_config] do
    puts "Compiling into #{COMPILED_FILE}"
    puts `#{APP_ROOT}/public/app/node_modules/.bin/tsc --project #{APP_ROOT}/public/app/js/tsconfig.json`
  end

  desc 'Minify compiled file'
  task minify: [:load_config, :ts2js] do
    puts "Minifying into #{MINIFIED_FILE}"
    puts `#{APP_ROOT}/public/app/node_modules/.bin/google-closure-compiler-js #{COMPILED_FILE} > #{MINIFIED_FILE}`
  end

  desc 'For production deployement'
  task production: [ :css, :minify ]
end

task preprocess_assets: 'preprocess_assets:production'
