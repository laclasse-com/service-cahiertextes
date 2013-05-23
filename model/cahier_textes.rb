#coding: utf-8
#
# model for 'cahier_textes' table
# generated 2013-05-23 15:29:33 +0200 by /Users/pgl/.rvm/gems/ruby-1.9.3-p194@global/bin/rake
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# regrpnt_id                    | int(11)             | false    |          |            | 
# lib                           | varchar(45)         | true     |          |            | 
# deb_annee_scolaire            | decimal(10,0)       | false    |          |            | 
# fin_annee_scolaire            | decimal(10,0)       | false    |          |            | 
# date_creation                 | datetime            | true     |          |            | 
# deleted                       | tinyint(1)          | true     |          | 0          | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class CahierTextes < Sequel::Model(:cahier_textes)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  plugin :composition

  # Referential integrity
  one_to_many :cours

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:regrpnt_id, :deb_annee_scolaire, :fin_annee_scolaire]
  end
end
