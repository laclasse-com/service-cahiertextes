#coding: utf-8
#
# model for 'Ressource' table
# generated 2012-12-12 15:07:48 +0100 by sequel_model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# lib                           | varchar(80)         | false    |          |            | 
# doc_id                        | int(11)             | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Ressource < Sequel::Model(:Ressource)

 # Plugins
 plugin :validation_helpers
 plugin :json_serializer

 # Referential integrity
 one_to_many :cours
 one_to_many :devoir
 one_to_many :log_visu

 # Not nullable cols
 def validate
 validates_presence [:lib]
 end
end
