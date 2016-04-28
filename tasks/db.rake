# coding: utf-8

ENV['RACK_ENV'] = 'development'
namespace :db do
  task :load_config do
    require_relative('../config/options')
    require(File.join(APP_ROOT, 'api'))
  end

  desc 'Apply migrations'
  task migrations: :load_config do
    Sequel::Migrator.run( DB, 'migrations' )
  end

  desc 'Apply migrations too'
  task migrate: :migrations

  desc 'Checks if a migration is needed'
  task check_migrate: :load_config do
    Sequel.extension :migration
    exit Sequel::Migrator.is_current?( Sequel::Model.db, 'migrations' ) ? 0 : 1
  end

  desc 'Dumps database'
  task dump: :load_config do
    STDERR.puts "Dumping database #{DB_CONFIG[:name]} into #{DB_CONFIG[:name]}_#{Time.now.strftime('%F')}.sql"
    `mysqldump -u #{DB_CONFIG[:user]} -p#{DB_CONFIG[:password]} #{DB_CONFIG[:name]} > #{DB_CONFIG[:name]}_#{Time.now.strftime('%F')}.sql` # rubocop:disable Metrics/LineLength
  end
end
