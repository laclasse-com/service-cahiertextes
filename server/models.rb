# -*- coding: utf-8 -*-
require 'sequel'
require 'sequel/extensions/migration'

#Connexion DB
DB = Sequel.sqlite( './cahier_de_texte.sqlite3' )

#application des migrations
Sequel::Migrator.run( DB, "migrations" )

#définition des modèles
class TrancheHoraire < Sequel::Model(:tranche_horaire)
  plugin :json_serializer
end
