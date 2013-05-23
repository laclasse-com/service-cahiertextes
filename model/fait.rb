#coding: utf-8
#
# model for 'fait' table
# generated 2013-05-23 15:29:33 +0200 by /Users/pgl/.rvm/gems/ruby-1.9.3-p194@global/bin/rake
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# usr_id                        | varchar(16)         | false    |          |            | 
# devoir_id                     | int(11)             | false    | MUL      |            | 
# date_fait                     | datetime            | true     |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Fait < Sequel::Model(:fait)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  plugin :composition

  # Referential integrity
  many_to_one :devoir

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:usr_id, :devoir_id]
  end
end
