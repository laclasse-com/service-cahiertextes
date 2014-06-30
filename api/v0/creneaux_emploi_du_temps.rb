# -*- coding: utf-8 -*-

require_relative '../../models/plage_horaire'
require_relative '../../models/creneau_emploi_du_temps'

module CahierDeTextesAPI
  module V0
    class CreneauxEmploiDuTempsAPI < Grape::API

      desc 'renvoi les créneaux'
      get  do
        CreneauEmploiDuTemps.all
      end

      desc 'renvoi un créneau'
      params {
        requires :id

        optional :expand, type: Boolean
        optional :debut, type: Date
        optional :fin, type: Date

      }
      get '/:id' do
        expand = !params[:expand].nil? && params[:expand] && !params[:debut].nil? && !params[:fin].nil?

        creneau = CreneauEmploiDuTemps[ params[:id] ]
        h = creneau.to_hash

        h[:regroupements] = creneau.regroupements.map { |e|
          e.semaines_de_presence = e.semaines_de_presence.to_s 2
          e
        }
        h[:enseignants] = creneau.enseignants.map { |e|
          e.semaines_de_presence = e.semaines_de_presence.to_s 2
          e
        }
        h[:salles] = creneau.salles.map { |e|
          e.semaines_de_presence = e.semaines_de_presence.to_s 2
          e
        }

        if expand
          h[:cours] = Cours.where( creneau_emploi_du_temps_id: params[:id] ).where( deleted: false ).where( date_cours: params[:debut] .. params[:fin] )
          h[:devoirs] = Devoir.where( creneau_emploi_du_temps_id: params[:id] ).where( date_due: params[:debut] .. params[:fin] )
        end

        h
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
          plage_horaire_debut = PlageHoraire.create(label: '',
                                                    debut: params[:heure_debut],
                                                    fin: params[:heure_debut] + 1800 )
        end

        plage_horaire_fin = PlageHoraire.where(fin: params[:heure_fin] ).first
        if plage_horaire_fin.nil?
          plage_horaire_fin = PlageHoraire.create(label: '',
                                                  debut: params[:heure_fin] - 1800,
                                                  fin: params[:heure_fin] )
        end

        creneau = CreneauEmploiDuTemps.create(debut: plage_horaire_debut.id,
                                              fin: plage_horaire_fin.id,
                                              jour_de_la_semaine: params[:jour_de_la_semaine] - 1, # FIXME: pas forcément toujours lundi
                                              matiere_id: params[:matiere_id] )
        CreneauEmploiDuTempsEnseignant.unrestrict_primary_key
        creneau.add_enseignant enseignant_id: user.uid
        CreneauEmploiDuTempsEnseignant.restrict_primary_key

        unless params[:regroupement_id].empty?
          CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
          creneau.add_regroupement regroupement_id: params[:regroupement_id]
          CreneauEmploiDuTempsRegroupement.restrict_primary_key
        end

        if params[:salle_id]
          CreneauEmploiDuTempsSalle.unrestrict_primary_key
          creneau.add_salle salle_id: params[:salle_id]
          CreneauEmploiDuTempsSalle.restrict_primary_key
        end

        creneau
      end

      desc 'modifie un créneau'
      params {
        requires :id, type: Integer
        requires :matiere_id
        requires :regroupement_id

        optional :heure_debut, type: Time
        optional :heure_fin, type: Time
        optional :salle_id
      }
      put '/:id'  do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.is?( 'DIR' )

        creneau = CreneauEmploiDuTemps[ params[:id] ]
        unless creneau.nil?

          if params[:heure_debut]
            plage_horaire_debut = PlageHoraire.where(debut: params[:heure_debut] ).first
            if plage_horaire_debut.nil?
              plage_horaire_debut = PlageHoraire.create(label: '',
                                                        debut: params[:heure_debut],
                                                        fin: params[:heure_debut] + 1800 )
            end
            creneau.debut = plage_horaire_debut.id
          end
          if params[:heure_fin]
            plage_horaire_fin = PlageHoraire.where(fin: params[:heure_fin] ).first
            if plage_horaire_fin.nil?
              plage_horaire_fin = PlageHoraire.create(label: '',
                                                      debut: params[:heure_fin] - 1800,
                                                      fin: params[:heure_fin] )
            end
            creneau.fin = plage_horaire_fin.id
          end
          creneau.matiere_id = params[:matiere_id]

          creneau.save

          if CreneauEmploiDuTempsRegroupement
              .where( creneau_emploi_du_temps_id: params[:id] )
              .where( regroupement_id: params[:regroupement_id] ).count < 1
            CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
            creneau.add_regroupement regroupement_id: params[:regroupement_id]
            CreneauEmploiDuTempsRegroupement.restrict_primary_key
          end

          if params[:salle_id]
            CreneauEmploiDuTempsSalle.unrestrict_primary_key
            creneau.add_salle salle_id: params[:salle_id]
            CreneauEmploiDuTempsSalle.restrict_primary_key
          end

          creneau
        end
      end

      desc 'Supprime un créneau'
      params {
        requires :id, type: Integer
        requires :date_creneau, type: Date
      }
      delete '/:id' do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'ENS' ) || user.is?( 'DIR' )

        creneau = CreneauEmploiDuTemps[ params[:id] ]
        unless creneau.nil?
          creneau.update( deleted: true, date_suppression: params[:date_creneau] )
          creneau.save

          creneau
        end
      end

    end
  end
end
