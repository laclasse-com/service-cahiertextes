# -*- coding: utf-8 -*-
require 'sequel'
require 'sequel/extensions/migration'

require_relative '../config/database'

# application des migrations
Sequel::Migrator.run( DB, 'migrations' )

# tous les modèles sérialisent en JSON
Sequel::Model.plugin :json_serializer

# Emploi du temps
require_relative './plage_horaire'
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
