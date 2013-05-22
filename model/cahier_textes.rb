#coding: utf-8
#
# model for 'cahier_textes' table
# generated 2012-12-12 15:12:21 +0100 by sequel_model_generator.rb
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

 # Referential integrity
 one_to_many :cours, :class => Cours

 # Not nullable cols
 def validate
 validates_presence [:regrpnt_id, :deb_annee_scolaire, :fin_annee_scolaire]
 end
end
