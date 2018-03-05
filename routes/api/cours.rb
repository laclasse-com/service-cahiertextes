require_relative '../../models/cours'

module CahierDeTextesApp
  module Routes
    module Api
      module CoursAPI
        def self.registered( app )
          app.get '/api/cours/?' do
            query = Cours

            query = query.where( enseignant_id: params['enseignants_ids'] ) if params.key?( 'enseignants_ids' )
            query = query.where( creneau_emploi_du_temps_id: params['creneaux_ids']) if params.key?( 'creneaux_ids' )
            query = query.where( Sequel.lit( "DATE_FORMAT( date_cours, '%Y-%m-%d') = '#{Date.parse( params['date_cours'] )}'" ) ) if params.key?( 'date_cours' )
            query = query.where( Sequel.lit( "DATE_FORMAT( date_cours, '%Y-%m-%d') >= '#{Date.parse( params['date_cours>'] )}'" ) ) if params.key?( 'date_cours>' )
            query = query.where( Sequel.lit( "DATE_FORMAT( date_cours, '%Y-%m-%d') <= '#{Date.parse( params['date_cours<'] )}'" ) ) if params.key?( 'date_cours<' )
            query = query.where( creneau_emploi_du_temps_id: CreneauEmploiDuTemps.where( regroupement_id: params['groups_ids'] ).select(:id).all.map(&:id) ) if params.key?( 'groups_ids' )

            json( query.naked.all )
          end

          app.get '/api/cours/:id/?' do
            cours = Cours[ id: params['id'] ]
            halt( 404, 'Cours inconnu' ) if cours.nil? || ( cours.deleted && cours.date_modification < UNDELETE_TIME_WINDOW.minutes.ago )

            json( cours.to_deep_hash )
          end

          app.post '/api/cours/?' do
            request.body.rewind
            body = JSON.parse( request.body.read )

            user_needs_to_be( %w[ ENS DOC ] )

            creneau = CreneauEmploiDuTemps[ body['creneau_emploi_du_temps_id'] ]
            halt( 409, 'Créneau invalide' ) if creneau.nil?

            cours = Cours.create( enseignant_id: user['id'],
                                  cahier_de_textes_id: DataManagement::Accessors.create_or_get( CahierDeTextes, regroupement_id: creneau.regroupement_id ).id,
                                  creneau_emploi_du_temps_id: creneau.id,
                                  date_cours: body['date_cours'].to_s,
                                  date_creation: Time.now,
                                  contenu: '' )

            cours.modifie( body )

            json( cours.to_deep_hash )
          end

          app.put '/api/cours/:id/?' do
            request.body.rewind
            body = JSON.parse( request.body.read )

            user_needs_to_be( %w[ ENS DOC ] )

            cours = Cours[ id: params['id'] ]

            halt( 404, 'Cours inconnu' ) if cours.nil?
            halt( 401, 'Cours visé non modifiable' ) unless cours.date_validation.nil?

            cours.modifie( body )

            json( cours.to_deep_hash )
          end

          app.put '/api/cours/:id/valide/?' do
            user_needs_to_be( %w[ DIR ] )

            cours = Cours[ id: params['id'] ]
            halt( 404, 'Cours inconnu' ) if cours.nil?

            cours.toggle_validated

            json( cours.to_deep_hash )
          end

          app.put '/api/cours/:id/copie/regroupement/:regroupement_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date/:date/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            cours = Cours[ id: params['id'] ]

            halt( 404, 'Cours inconnu' ) if cours.nil?

            nouveau_cours = cours.copie( params['regroupement_id'], params['creneau_emploi_du_temps_id'], params['date'] )

            hash = cours.to_deep_hash
            hash[:copie_id] = nouveau_cours[:id]

            json( hash )
          end

          app.delete '/api/cours/:id/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            cours = Cours[ id: params['id'] ]
            halt( 404, 'Cours inconnu' ) if cours.nil?
            halt( 401, 'Cours visé non modifiable' ) unless cours.date_validation.nil?

            cours.toggle_deleted

            json( cours.to_deep_hash )
          end
        end
      end
    end
  end
end
