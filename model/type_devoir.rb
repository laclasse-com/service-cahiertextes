#coding: utf-8
#
# model for 'type_devoir' table
# generated 2012-12-12 15:12:21 +0100 by sequel_model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | 
# lib                           | varchar(80)         | true     |          |            | 
# description                   | text                | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class TypeDevoir < Sequel::Model(:type_devoir)

 # Plugins
 plugin :validation_helpers
 plugin :json_serializer

 # Referential integrity
 one_to_many :devoir, :key=>:Type_devoir_id

 # Not nullable cols
 def validate
 end
end
