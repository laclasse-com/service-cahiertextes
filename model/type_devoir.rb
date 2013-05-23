#coding: utf-8
#
# model for 'type_devoir' table
# generated 2013-05-23 15:29:33 +0200 by /Users/pgl/.rvm/gems/ruby-1.9.3-p194@global/bin/rake
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
  plugin :composition

  # Referential integrity
  one_to_many :devoir, :key=>:Type_devoir_id

  # Not nullable cols and unicity validation
  def validate
    super
  end
end
