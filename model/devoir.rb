#coding: utf-8
#
# model for 'devoir' table
# generated 2013-05-23 15:29:33 +0200 by /Users/pgl/.rvm/gems/ruby-1.9.3-p194@global/bin/rake
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# Type_devoir_id                | int(11)             | false    | MUL      |            | 
# cours_id                      | int(11)             | true     | MUL      |            | 
# Ressource_id                  | int(11)             | true     |          |            | 
# contenu                       | text                | true     |          |            | 
# temps_estime                  | int(11)             | true     |          |            | 
# date_devoir                   | datetime            | true     |          |            | 
# date_creation                 | datetime            | true     |          |            | 
# date_modif                    | datetime            | true     |          |            | 
# date_valid                    | datetime            | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Devoir < Sequel::Model(:devoir)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  plugin :composition

  # Referential integrity
  many_to_one :type_devoir, :key=>:Type_devoir_id
  many_to_one :cours
  one_to_many :fait

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:Type_devoir_id]
  end
end
