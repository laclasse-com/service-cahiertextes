#coding: utf-8
#
# model for 'plage_horaire' table
# generated 2012-12-12 15:12:21 +0100 by sequel_model_generator.rb
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

 # Referential integrity
 one_to_many :cours

 # Not nullable cols
 def validate
 end
end
