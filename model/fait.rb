#coding: utf-8
#
# model for 'fait' table
# generated 2012-12-12 15:07:48 +0100 by sequel_model_generator.rb
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# usr_id                        | varchar(16)         | true     |          |            | 
# devoir_id                     | int(11)             | false    | MUL      |            | 
# date_fait                     | datetime            | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Fait < Sequel::Model(:fait)

 # Plugins
 plugin :validation_helpers
 plugin :json_serializer

 # Referential integrity
 many_to_one :devoir

 # Not nullable cols
 def validate
 validates_presence [:devoir_id]
 end
end
