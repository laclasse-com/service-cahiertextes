#coding: utf-8
#
# model for 'log_visu' table
# generated 2012-12-12 15:07:48 +0100 by sequel_model_generator.rb
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

 # Referential integrity
 many_to_one :Ressource

 # Not nullable cols
 def validate
 end
end
