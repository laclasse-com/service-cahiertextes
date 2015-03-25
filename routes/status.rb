# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Status
      def self.registered( app )
        app.get "#{APP_PATH}/status/?" do
          { status: 'OK',
            nb_etablissements: Etablissement.count,
            nb_cahiers_de_textes: CahierDeTextes.count,
            nb_sequences_pedagogiques: Cours.count,
            nb_devoirs: Devoir.count,
            nb_devoirs_faits: DevoirTodoItem.count,
            nb_ressources: Ressource.count,
            nb_utilisateurs_actifs: UserParameters.count,
            nb_creneaux_emploi_du_temps: CreneauEmploiDuTemps.count }
        end
      end
    end
  end
end
