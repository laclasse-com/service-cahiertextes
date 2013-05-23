#coding: utf-8
#
# model for 'plage_horaire' table
# generated 2013-05-23 15:29:33 +0200 by /Users/pgl/.rvm/gems/ruby-1.9.3-p194@global/bin/rake
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | varchar(10)         | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class PlageHoraire < Sequel::Model(:plage_horaire)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  plugin :composition

  # Referential integrity
  one_to_many :cours

  # Not nullable cols and unicity validation
  def validate
    super
  end
end
