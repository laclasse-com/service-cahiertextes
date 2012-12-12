#coding: utf-8
#
# model for 'devoir' table
# generated 2012-12-12 15:12:21 +0100 by sequel_model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# Type_devoir_id                | int(11)             | false    | MUL      |            | 
# cours_id                      | int(11)             | false    | MUL      |            | 
# Ressource_id                  | int(11)             | true     | MUL      |            | 
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

 # Referential integrity
 many_to_one :Ressource
 many_to_one :type_devoir, :key=>:Type_devoir_id
 many_to_one :cours
 one_to_many :fait

 # Not nullable cols
 def validate
 validates_presence [:Type_devoir_id, :cours_id]
 end
end
