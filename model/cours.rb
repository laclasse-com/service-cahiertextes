#coding: utf-8
#
# model for 'cours' table
# generated 2013-05-23 15:29:33 +0200 by /Users/pgl/.rvm/gems/ruby-1.9.3-p194@global/bin/rake
#
# ------------------------------+---------------------+----------+----------+------------+--------------------
# COLUMN_NAME                   | DATA_TYPE           | NULL? | KEY | DEFAULT | EXTRA
# ------------------------------+---------------------+----------+----------+------------+--------------------
# id                            | int(11)             | false    | PRI      |            | auto_increment
# usr_id                        | varchar(16)         | false    | MUL      |            | 
# mat_id                        | varchar(16)         | false    | MUL      |            | 
# cahier_textes_id              | int(11)             | false    | MUL      |            | 
# Ressource_id                  | int(11)             | true     |          |            | 
# plage_horaire_id              | varchar(10)         | false    | MUL      |            | 
# contenu                       | text                | false    |          |            | 
# date_cours                    | datetime            | true     |          |            | 
# date_creation                 | datetime            | true     |          |            | 
# date_modif                    | datetime            | true     |          |            | 
# date_valid                    | datetime            | true     |          |            | 
# deleted                       | tinyint(1)          | false    |          | 0          | 
# ------------------------------+---------------------+----------+----------+------------+--------------------
#
class Cours < Sequel::Model(:cours)

  # Plugins
  plugin :validation_helpers
  plugin :json_serializer
  plugin :composition

  # Referential integrity
  many_to_one :cahier_textes
  many_to_one :plage_horaire
  one_to_many :devoir

  # Not nullable cols and unicity validation
  def validate
    super
    validates_presence [:usr_id, :mat_id, :cahier_textes_id, :plage_horaire_id, :contenu]
  end
end
