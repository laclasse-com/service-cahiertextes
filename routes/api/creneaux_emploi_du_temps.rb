module CahierDeTextesApp
  module Routes
    module Api
      module CreneauxEmploiDuTemps
        def self.registered( app )
          app.get '/api/creneaux_emploi_du_temps/?' do
            query = CreneauEmploiDuTemps

            query = query.where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) ) unless params.key?( 'no_year_restriction' )
            query = query.where( Sequel.lit( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( date_suppression, '%Y-%m-%d') >= '#{Date.parse( params['date<'] )}')" ) ) if params.key?('date<') && !params.key?( 'include_deleted')
            query = query.where( regroupement_id: params['groups_ids'] ) if params.key?( 'groups_ids' )
            query = query.where( matiere_id: params['subjects_ids'] ) if params.key?( 'subjects_ids' )
            query = query.where( etablissement_id: params['structure_id'] ) if params.key?( 'structure_id' )
            query = query.where( import_id: params['import_id'] ) if params.key?( 'import_id' )

            data = query.naked.all

            if params.key?('date<') && params.key?('date>')
              data = data.select do |creneau|
                # ( !creneau.deleted || ( from > creneau.date_suppression && creneau.date_suppression > to ) ) &&
                ( (Date.parse(params['date>']) .. Date.parse(params['date<'])).reduce(true) { |memo, day| memo && (day.wday == creneau.jour_de_la_semaine && creneau.semainier[day.cweek] == 1) } )
              end
            end

            json( data )
          end

          app.get '/api/creneaux_emploi_du_temps/:id/?' do
            creneau = CreneauEmploiDuTemps[ id: params['id'] ]

            halt( 404, 'Créneau inconnu' ) if creneau.nil?

            json( creneau.detailed( params['debut'], params['fin'], %w[salles cours devoirs] ) )
          end

          app.get '/api/creneaux_emploi_du_temps/:id/similaires/?' do
            creneau = CreneauEmploiDuTemps[ id: params['id'] ]

            halt( 404, 'Créneau inconnu' ) if creneau.nil?

            json( creneau.similaires( params['groups_ids'], params['debut'], params['fin'] ) )
          end

          app.post '/api/creneaux_emploi_du_temps/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            etablissement = DataManagement::Accessors.create_or_get( Etablissement,
                                                                     UAI: user_active_profile['structure_id'] )

            creneau = CreneauEmploiDuTemps.create( date_creation: Time.now,
                                                   debut: params['heure_debut'],
                                                   fin: params['heure_fin'],
                                                   jour_de_la_semaine: params['jour_de_la_semaine'].to_i - 1,
                                                   matiere_id: params['matiere_id'],
                                                   regroupement_id: params['regroupement_id'],
                                                   etablissement_id: etablissement.id )

            creneau.modifie( params )

            json( creneau.to_hash )
          end

          app.post '/api/creneaux_emploi_du_temps/bulk/?' do
            request.body.rewind
            body = JSON.parse( request.body.read )

            etablissement = DataManagement::Accessors.create_or_get( Etablissement,
                                                                     UAI: body['uai'] )

            json( body['creneaux_emploi_du_temps'].map do |creneau|
                    new_creneau = CreneauEmploiDuTemps.create( date_creation: Time.now,
                                                               debut: creneau['heure_debut'],
                                                               fin: creneau['heure_fin'],
                                                               jour_de_la_semaine: creneau['jour_de_la_semaine'] - 1,
                                                               matiere_id: creneau['matiere_id'],
                                                               regroupement_id: creneau['regroupement_id'],
                                                               etablissement_id: etablissement.id )
                    new_creneau.modifie( creneau )

                    new_creneau.to_hash
                  end )
          end

          app.put '/api/creneaux_emploi_du_temps/:id/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            creneau = CreneauEmploiDuTemps[ params['id'] ]

            halt( 404, 'Créneau inconnu' ) if creneau.nil?

            creneau.modifie( params )

            json( creneau.to_hash )
          end

          app.delete '/api/creneaux_emploi_du_temps/:id/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            creneau = CreneauEmploiDuTemps[ params['id'] ]

            halt( 404, 'Créneau inconnu' ) if creneau.nil?

            if creneau.matiere_id.empty? && creneau.cours.empty? && creneau.devoirs.empty?
              creneau.deep_destroy
            else
              creneau.toggle_deleted( params['date_creneau'] )
            end

            json( creneau.to_hash )
          end
        end
      end
    end
  end
end
