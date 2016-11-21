# -*- coding: utf-8 -*-
require 'sequel'
require 'sequel/extensions/migration'

require_relative '../config/database'

# tous les modèles sérialisent en JSON
Sequel::Model.plugin :json_serializer

# Emploi du temps
require_relative './etablissement'
require_relative './salle'
require_relative './creneau_emploi_du_temps'

# Cahier de textes
require_relative './cahier_de_textes'
require_relative './ressource'

# Séquences pédagogiques
require_relative './cours'

# Devoirs
require_relative './devoir'

# Données non identifiable par l'annuaire lors des imports (Pronote, UDT, ...)
require_relative './failed_identification'

# Paramètres utilisateur
require_relative './user_parameters'

# Imports
require_relative './import'
