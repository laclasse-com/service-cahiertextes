# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Status
      def self.registered( app )
        app.get "#{APP_PATH}/status/?" do
          content_type :json

          status = 'OK'
          reason = 'L\'application Cahier de Textes fonctionne.'

          # test DB
          if DB.nil?
            status = 'KO'
            reason = 'Base de données inaccessible.'
          end
          if DB.tables.empty?
            status = 'KO'
            reason = 'Base de données vide.'
          end

          app_status = app_infos

          app_status[:status] = status
          app_status[:reason] = reason

          app_status.to_json
        end

        app.get "#{APP_PATH}/status/report/?" do
          content_type :json

          { nb_etablissements: Etablissement.count,
            nb_cahiers_de_textes: CahierDeTextes.count,
            nb_sequences_pedagogiques: Cours.count,
            nb_devoirs: Devoir.count,
            nb_devoirs_faits: DevoirTodoItem.count,
            nb_ressources: Ressource.count,
            nb_utilisateurs_actifs: UserParameters.count,
            nb_creneaux_emploi_du_temps: CreneauEmploiDuTemps.count }.to_json
        end
      end
    end
  end
end
