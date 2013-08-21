# -*- coding: utf-8 -*-
require 'sequel'
require 'sequel/extensions/migration'

#Connexion DB
DB = Sequel.sqlite( './cahier_de_texte.sqlite3' )

#application des migrations
Sequel::Migrator.run( DB, "migrations" )

#tous les modèles sérialisent en JSON
Sequel::Model.plugin :json_serializer

#définition des modèles
class PlageHoraire < Sequel::Model(:plage_horaire)
end

class Salle < Sequel::Model(:salle)
end

class Cours < Sequel::Model(:cours)
end
