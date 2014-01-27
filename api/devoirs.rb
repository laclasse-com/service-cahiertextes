# -*- coding: utf-8 -*-

module CahierDeTextesAPI
   # API d'accès aux devoirs
   # Utilisée par les :
   #   - élèves pour consultation et gestion todo-list
   #   - enseignants pour consultation et édition
   #   - principaux pour consultation
   class DevoirsAPI < Grape::API

      desc 'renvoi tous les devoirs concernant l\'utilisateur durant la période donnée'
      params {
         optional :from, type: Date
         optional :to, type: Date
      }
      get '/' do
         # TODO: prendre en compte debut et fin

         return [] if user['classes'].nil?

         regroupements_ids = user['classes'].map {
            |classe|
            classe['classe_id']
         }.uniq

         Devoir.select( :devoirs__id,
                        :devoirs__cours_id,
                        :devoirs__type_devoir_id,
                        :devoirs__contenu,
                        :devoirs__date_creation,
                        :devoirs__date_modification,
                        :devoirs__date_validation,
                        :devoirs__date_due,
                        :devoirs__temps_estime)
         .join(:cours, id: :cours_id)
         .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :id)
         .where( regroupement_id: regroupements_ids )
         .map { |devoir|
            hash = devoir.to_hash
            hash[:ressources] = devoir.ressources
            hash[:fait] = devoir.fait_par?( params[ :eleve_id ] )

            hash
         }
      end

      desc 'renvoi le détail d\'un devoir'
      params {
         requires :id
      }
      get '/:id' do
         devoir = Devoir[ params[:id] ]
         if devoir.nil?
            error!( 'Devoir inconnu', 404 )
         else
            eleve_id = user['uid']

            hash = devoir.to_hash
            hash[:ressources] = devoir.ressources
            hash[:fait] = devoir.fait_par?( eleve_id )

            hash
         end
      end

      desc 'renseigne un devoir'
      params {
         requires :cours_id
         requires :type_devoir_id
         requires :contenu
         requires :date_due, type: Date
         optional :ressources
      }
      post  do
         error!( '401 Unauthorized', 401 ) unless user_is?( 'ENS', '0699999Z' ) || user_is?( 'DIR', '0699999Z' )

         if Cours[ params[:cours_id] ].nil?
            error!( 'Cours inconnu', 404 )
         else
            # 1. trouver le créneau cible
            creneau_emploi_du_temps = CreneauEmploiDuTemps
            .where(matiere_id: CreneauEmploiDuTemps[ Cours[ params[:cours_id] ].creneau_emploi_du_temps_id ].matiere_id)
            .where(jour_de_la_semaine: params[:date_due].wday)
            .join(:creneaux_emploi_du_temps_enseignants, creneau_emploi_du_temps_id: :id)
            .where(enseignant_id: Cours[ params[:cours_id] ].enseignant_id)
            .first                # FIXME: arbitrairement on choisi d'attacher le devoir au premier créneau

            # 2. création du devoir
            if creneau_emploi_du_temps.nil?
               error!( 'Date due impossible', 418 ) # FIXME: trouver un meilleur code
            else
               devoir = Devoir.create( cours_id: params[:cours_id],
                  type_devoir_id: params[:type_devoir_id],
                  creneau_emploi_du_temps_id: creneau_emploi_du_temps.id,
                  contenu: params[:contenu],
                  date_due: params[:date_due],
                  temps_estime: params[:temps_estime],
                  date_creation: Time.now)

               # 3. traitement des ressources
               params[:ressources] && params[:ressources].each do
                  |ressource|
                  devoir.add_ressource( Ressource.create( label: ressource['label'],
                     url: ressource['url'] ) )
               end

               devoir
            end
         end
      end

      desc 'modifie un devoir'
      params {
         requires :id
         requires :type_devoir_id
         requires :contenu
         requires :date_due, type: Date
         optional :ressources
      }
      put '/:id' do
         error!( '401 Unauthorized', 401 ) unless user_is?( 'ENS', '0699999Z' ) || user_is?( 'DIR', '0699999Z' )

         devoir = Devoir[ params[:id] ]
         if devoir.nil?
            error!( 'Devoir inconnu', 404 )
         else
            if devoir.date_due != params[:date_due]
               creneau_emploi_du_temps = CreneauEmploiDuTemps
               .where(matiere_id: CreneauEmploiDuTemps[ Cours[ params[:cours_id] ].creneau_emploi_du_temps_id ].matiere_id)
               .where(jour_de_la_semaine: params[:date_due].wday)
               .join(:creneaux_emploi_du_temps_enseignants, creneau_emploi_du_temps_id: :id)
               .where(enseignant_id: Cours[ params[:cours_id] ].enseignant_id)
               .first                # FIXME: arbitrairement on choisi d'attacher le devoir au premier créneau

               if creneau_emploi_du_temps.nil?
                  error!( 'Date due impossible', 418 ) # FIXME: trouver un meilleur code
               else
                  devoir.date_due = params[:date_due]
                  devoir.creneau_emploi_du_temps_id = creneau_emploi_du_temps.id
               end
            end

            devoir.type_devoir_id = params[:type_devoir_id]
            devoir.contenu = params[:contenu]
            devoir.temps_estime = params[:temps_estime]

            params[:ressources] && params[:ressources].each do
               |ressource|
               devoir.add_ressource( Ressource.create( label: ressource['label'],
                  url: ressource['url'] ) )
            end

            devoir.date_modification = Time.now
            devoir.save
         end
      end

      desc 'marque un devoir comme fait'
      params {
         requires :id
      }
      put '/:id/fait' do
         error!( '401 Unauthorized', 401 ) unless user_is? 'ELV', '0699999Z'

         eleve_id = user['uid']

         Devoir[ params[:id] ].fait_par!( eleve_id )
      end

   end
end
