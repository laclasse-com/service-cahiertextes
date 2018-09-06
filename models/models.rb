# coding: utf-8
require 'sequel'
require 'sequel/extensions/migration'

# tous les modèles sérialisent en JSON
Sequel::Model.plugin :json_serializer

# Emploi du temps
require_relative './structure'
require_relative './salle'
require_relative './timeslot'

# Cahier de textes
require_relative './textbook'
require_relative './ressource'

# Séquences pédagogiques
require_relative './cours'

# Devoirs
require_relative './devoir'

# Données non identifiable par l'annuaire lors des imports (Pronote, UDT, ...)
require_relative './matchable'

# Paramètres utilisateur
require_relative './user_parameters'

# Imports
require_relative './import'
