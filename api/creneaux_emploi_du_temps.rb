# -*- coding: utf-8 -*-

require_relative '../models/plage_horaire'
require_relative '../models/creneau_emploi_du_temps'

module CahierDeTextesAPI
   class CreneauxEmploiDuTempsAPI < Grape::API

      desc 'renvoi les créneaux'
      get  do
         CreneauEmploiDuTemps.all
      end

      desc 'renvoi un créneau'
      params {
         requires :id
      }
      get '/:id' do
         CreneauEmploiDuTemps[ params[:id] ]
      end

      desc 'crée un créneau s\'il n\'existe pas déjà un semblable'
      params {
         requires :jour_de_la_semaine, type: Integer
         requires :heure_debut, type: Time
         requires :heure_fin, type: Time
         requires :matiere_id
         requires :regroupement_id

         optional :salle_id
      }
      post  do
         plage_horaire_debut = PlageHoraire.where(debut: params[:heure_debut] ).first
         if plage_horaire_debut.nil?
            plage_horaire_debut = PlageHoraire.create( label: '',
                                                         debut: params[:heure_debut],
                                                         fin: params[:heure_debut] + 1800 )
         end

         plage_horaire_fin = PlageHoraire.where(fin: params[:heure_fin] ).first
         if plage_horaire_fin.nil?
            plage_horaire_fin = PlageHoraire.create( label: '',
                                                       debut: params[:heure_fin] - 1800,
                                                       fin: params[:heure_fin] )
         end

         creneau = CreneauEmploiDuTemps.create( debut: plage_horaire_debut.id,
            fin: plage_horaire_fin.id,
            jour_de_la_semaine: params[:jour_de_la_semaine] - 1, # FIXME: pas toujours lundi
            matiere_id: params[:matiere_id] )
         CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
         CreneauEmploiDuTempsEnseignant.create( creneau_emploi_du_temps_id: creneau.id,
            enseignant_id: user.uid )
         CreneauEmploiDuTempsEnseignant.restrict_primary_key

         unless params[:regroupement_id].empty?
            CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
            CreneauEmploiDuTempsRegroupement.create( creneau_emploi_du_temps_id: creneau.id,
               regroupement_id: params[:regroupement_id] )
            CreneauEmploiDuTempsRegroupement.restrict_primary_key
         end

         if params[:salle_id]
            CreneauEmploiDuTempsSalle.unrestrict_primary_key
            CreneauEmploiDuTempsSalle.create( creneau_emploi_du_temps_id: creneau.id,
                                                salle_id: params[:salle_id] )
            CreneauEmploiDuTempsSalle.restrict_primary_key
         end

         creneau
      end

      desc 'modifie un créneau'
      params {
         requires :id, type: Integer
         requires :matiere_id
         requires :regroupement_id

         optional :salle_id
      }
      put '/:id'  do
         error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS', user.ENTPersonStructRattachRNE ) || user.is?( 'DIR', user.ENTPersonStructRattachRNE )

         creneau = CreneauEmploiDuTemps[ params[:id] ]
         unless creneau.nil?
            creneau.matiere_id = params[:matiere_id]

            creneau.save

            if CreneauEmploiDuTempsRegroupement
               .where( creneau_emploi_du_temps_id: params[:id] )
               .where( regroupement_id: params[:regroupement_id] ).count < 1

               CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
               CreneauEmploiDuTempsRegroupement.create( creneau_emploi_du_temps_id: creneau.id,
                  regroupement_id: params[:regroupement_id] )
               CreneauEmploiDuTempsRegroupement.restrict_primary_key
            end

            # if params[:salle_id]
            #    CreneauEmploiDuTempsSalle.unrestrict_primary_key
            #    CreneauEmploiDuTempsSalle.create( creneau_emploi_du_temps_id: creneau.id,
            #       salle_id: params[:salle_id] )
            #    CreneauEmploiDuTempsSalle.restrict_primary_key
            # end

            creneau
         end
      end

   end
end
