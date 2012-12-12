require 'sequel'
Sequel.extension(:pagination)

DB=Sequel.mysql2(
  'cahiertextes',
  :user     => 'root',
  :password => '')
