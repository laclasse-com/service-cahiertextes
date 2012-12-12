require 'sequel'
Sequel.extension(:pagination)

DB=Sequel.mysql2(
  'cahiertextes',
  :user     => 'root',
  :password => '',
  :charset=>'utf8')


#Uncomment this if you want to log all DB queries
#require 'logger'
#DB.loggers << Logger.new($stdout)
