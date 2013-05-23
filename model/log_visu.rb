#coding: utf-8
#
# model for 'log_visu' table
# generated 2013-05-23 15:29:33 +0200 by /Users/pgl/.rvm/gems/ruby-1.9.3-p194@global/bin/rake
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# usr_id                        | int(11)             | false    | PRI      |            | 
# Ressource_id                  | int(11)             | false    | PRI      |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class LogVisu < Sequel::Model(:log_visu)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  plugin :composition

  # Referential integrity
  many_to_one :ressource, :key=>:Ressource_id

  # Not nullable cols and unicity validation
  def validate
    super
  end
end
