namespace :db do
  task :load_config do
    require(File.join(APP_ROOT, 'app'))
  end

  desc "Configuring database server."
  task :configure do
    require 'erb'
    File.open(File.join(APP_ROOT,'config', 'database.rb'), 'w') do |new_file|
      new_file.write ERB.new(File.read(File.join(APP_ROOT, 'config', 'database.erb'))).result(binding)
    end
  end
    
  desc "Dumps the schema to db/schema/sequel_schema.db"
  task :schemadump => :load_config do
    #foreign_key dump is sometimes wrong with non autoincrmente type (ie char)
    #so we need to dump the base in two times : the structure without foreign_keys and the foreigne_key alone
    schema = DB.dump_schema_migration(:foreign_key => false)
    schema_file = File.open(File.join(APP_ROOT, 'db', 'scripst', 'dump_db_schema.sql'), "w"){|f| f.write(schema)}
    fk = DB.dump_foreign_key_migration
    fk_file = File.open(File.join(APP_ROOT, 'db', 'scripts', 'dump_fk.sql'), "w"){|f| f.write(fk)}
  end
  
  desc "Generating Sequel model from database."
  task :generate_model => :load_config do 
    require_relative '../lib/model_generator'
  end 

  desc "Apply migrations"
  task :migrations => :load_config do
    Sequel::Migrator.run( DB, 'migrations' )
  end
end
