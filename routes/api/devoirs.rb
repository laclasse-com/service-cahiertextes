# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Api
      module Devoirs
        def self.registered( app )
          app.get '/api/devoirs/?' do
            halt( 401, '401 Unauthorized' ) unless !params.key?('uid') || ( ( user['id'] == params['uid'] ) ||
                                                                            ( user_active_profile['type'] == 'TUT' &&
                                                                              !user['children'].find { |child| child['child_id'] == params['uid'] }.nil? ) )

            query = Devoir

            query = query.where( creneau_emploi_du_temps_id: params['creneaux_ids']) if params.key?( 'creneaux_ids' )

            query = query.where( creneau_emploi_du_temps_id: CreneauEmploiDuTemps.where( regroupement_id: params['groups_ids'] ).select(:id).all.map(&:id) ) if params.key?( 'groups_ids' )

            query = query.where( cours_id: params['cours_ids']) if params.key?( 'cours_ids' )

            query = query.where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') >= '#{Date.parse( params['date_due>'] )}'" ) ) if params.key?( 'date_due>' )

            query = query.where( Sequel.lit( "DATE_FORMAT( date_due, '%Y-%m-%d') <= '#{Date.parse( params['date_due<'] )}'" ) ) if params.key?( 'date_due<' )

            query = query.where( Sequel.~( Sequel.qualify( 'devoirs', 'deleted' ) ) ) unless params.key?( 'include_deleted')

            data = query.naked.all.map(&:to_deep_hash)

            if params.key?('uid') && params.key?('check_done') && params['check_done'] == 'true'
              data.each do |devoir|
                dti = DevoirTodoItem[ devoir_id: devoir[:id], eleve_id: params['uid'] ]
                devoir[:date_fait] = dti.date_fait unless dti.nil?
                devoir[:fait] = !dti.nil?
              end
            end

            json( data )
          end

          app.get '/api/devoirs/:id/?' do
            devoir = Devoir[ params['id'] ]

            halt( 404, 'Devoir inconnu' ) if devoir.nil? || ( devoir.deleted && devoir.date_modification < UNDELETE_TIME_WINDOW.minutes.ago )

            hd = devoir.to_deep_hash
            if params['uid']
              dti = DevoirTodoItem[ devoir_id: devoir.id, eleve_id: user['id'] ]
              hd[:date_fait] = dti.date_fait unless dti.nil?
            end

            json( hd )
          end

          app.post '/api/devoirs/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            request.body.rewind
            body = JSON.parse( request.body.read )

            creneau = CreneauEmploiDuTemps[ body['creneau_emploi_du_temps_id'] ]
            halt( 409, 'Créneau invalide' ) if creneau.nil?

            devoir = Devoir.create( enseignant_id: user['id'],
                                    type_devoir_id: body['type_devoir_id'],
                                    creneau_emploi_du_temps_id: creneau.id,
                                    contenu: body['contenu'],
                                    date_due: body['date_due'],
                                    temps_estime: body['temps_estime'],
                                    date_creation: Time.now )

            if body['cours_id'] && !body['cours_id'].nil?
              devoir.update( cours_id: body['cours_id'] )
            else
              cours = Cours.where( creneau_emploi_du_temps_id: creneau.id )
                           .where( date_cours: body['date_due'] )
                           .where( deleted: false )
                           .first
              if cours.nil?
                cours = Cours.create( enseignant_id: user['id'],
                                      cahier_de_textes_id: DataManagement::Accessors.create_or_get( CahierDeTextes, regroupement_id: creneau.regroupement_id ).id,
                                      creneau_emploi_du_temps_id: creneau.id,
                                      date_cours: body['date_due'],
                                      date_creation: Time.now,
                                      contenu: '' )
              end
              devoir.update( cours_id: cours.id )
            end

            params['enseignant_id'] = user['id']

            devoir.modifie( body )

            json( devoir.to_deep_hash )
          end

          app.put '/api/devoirs/:id/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            request.body.rewind
            body = JSON.parse( request.body.read )

            devoir = Devoir[ params['id'] ]
            halt( 404, 'Devoir inconnu' ) if devoir.nil?
            params['enseignant_id'] = user['id']

            devoir.modifie( body )

            json( devoir.to_deep_hash )
          end

          app.put '/api/devoirs/:id/fait/?' do
            user_needs_to_be( %w[ ELV ] )

            devoir = Devoir[ params['id'] ]

            devoir.toggle_fait( user )

            hd = devoir.to_deep_hash
            dti = DevoirTodoItem[ devoir_id: devoir.id, eleve_id: user['id'] ]
            hd[:date_fait] = dti.date_fait unless dti.nil?
            hd[:fait] = !dti.nil?

            json( hd )
          end

          app.delete '/api/devoirs/:id/?' do
            user_needs_to_be( %w[ ENS DOC ] )

            devoir = Devoir[ params['id'] ]

            devoir.toggle_deleted

            json( devoir.to_deep_hash )
          end

          app.put '/api/devoirs/:id/copie/cours/:cours_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date_due/:date_due' do
            user_needs_to_be( %w[ ENS DOC ] )

            # request.body.rewind
            # body = JSON.parse( request.body.read )

            devoir = Devoir[ params['id'] ]
            halt( 404, 'Devoir inconnu' ) if devoir.nil?

            devoir.copie( params['cours_id'], params['creneau_emploi_du_temps_id'], params['date_due'] )

            json( devoir.to_deep_hash )
          end
        end
      end
    end
  end
end
