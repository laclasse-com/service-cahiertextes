# coding: utf-8
require 'sequel'
require 'sequel/extensions/migration'

# tous les modèles sérialisent en JSON
Sequel::Model.plugin :json_serializer

# Emploi du temps
require_relative './structure'
require_relative './location'
require_relative './timeslot'

# Cahier de textes
require_relative './textbook'
require_relative './resource'

# Séquences pédagogiques
require_relative './session'

# Assignments
require_relative './assignment'

# Données non identifiable par l'annuaire lors des imports (Pronote, UDT, ...)
require_relative './matchable'

# Paramètres utilisateur
require_relative './user_parameters'

# Imports
require_relative './import'
