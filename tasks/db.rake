# coding: utf-8

ENV['RACK_ENV'] = 'development'
namespace :db do
  task :load_config do
    require_relative('../config/options')
    require(File.join(APP_ROOT, 'api'))
  end

  desc 'Dumps the schema to db/schema/sequel_schema.db'
  task schemadump: :load_config do
    require './config/database'
    # foreign_key dump is sometimes wrong with non autoincrmente type (ie char)
    # so we need to dump the base in two times : the structure without foreign_keys and the foreigne_key alone
    schema = DB.dump_schema_migration(foreign_key: false)
    File.open(File.join(APP_ROOT, 'db', 'scripts', 'dump_db_schema.sql'), 'w'){|f| f.write(schema)}
    fk = DB.dump_foreign_key_migration
    File.open(File.join(APP_ROOT, 'db', 'scripts', 'dump_fk.sql'), 'w'){|f| f.write(fk)}
  end

  desc 'Generating Sequel model from database.'
  task generate_model: :load_config do
    require_relative '../lib/model_generator'
  end

  desc 'Apply migrations'
  task migrations: :load_config do
    Sequel::Migrator.run( DB, 'migrations' )
  end

  desc "Checks if a migration is needed"
  task check_migrate: :load_config do
    Sequel.extension :migration
    exit Sequel::Migrator.is_current?( Sequel::Model.db, 'migrations' ) ? 0 : 1
  end
end
