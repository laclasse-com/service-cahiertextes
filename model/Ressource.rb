#coding: utf-8
#
# model for 'ressource' table
# generated 2013-05-23 15:29:33 +0200 by /Users/pgl/.rvm/gems/ruby-1.9.3-p194@global/bin/rake
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# lib                           | varchar(80)         | false    |          |            | 
# doc_id                        | int(11)             | false    |          |            | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Ressource < Sequel::Model(:ressource)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  plugin :composition

  # Referential integrity
  one_to_many :log_visu, :key=>:Ressource_id

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:lib, :doc_id]
  end
end
