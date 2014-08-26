# -*- coding: utf-8 -*-

require_relative '../../models/plage_horaire'
require_relative '../../models/creneau_emploi_du_temps'

module CahierDeTextesAPI
  module V1
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

        h[:regroupements] = creneau.regroupements
        h[:enseignants] = creneau.enseignants
        h[:salles] = creneau.salles

        if expand
          h[:cours] = Cours.where( creneau_emploi_du_temps_id: params[:id] ).where( deleted: false ).where( date_cours: params[:debut] .. params[:fin] )
          h[:devoirs] = Devoir.where( creneau_emploi_du_temps_id: params[:id] ).where( date_due: params[:debut] .. params[:fin] )
        end

        h
      end

      desc 'crée un créneau'
      params {
        requires :jour_de_la_semaine, type: Integer
        requires :heure_debut, type: Time
        requires :heure_fin, type: Time
        requires :matiere_id
        requires :regroupement_id

        optional :salle_id
        optional :semaines_de_presence_regroupement, type: Fixnum
        optional :semaines_de_presence_enseignant, type: Fixnum
        optional :semaines_de_presence_salle, type: Fixnum
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
        ce = creneau.add_enseignant enseignant_id: user.uid
        ce.update semaines_de_presence: params[:semaines_de_presence_enseignant] if params[:semaines_de_presence_enseignant]
        CreneauEmploiDuTempsEnseignant.restrict_primary_key

        unless params[:regroupement_id].nil? || params[:regroupement_id].empty? || params[:regroupement_id] == 'undefined'
          CahierDeTextes.create( regroupement_id: params[:regroupement_id] ) if  CahierDeTextes.where( regroupement_id: creneau[:regroupement_id] ).first.nil?

          CreneauEmploiDuTempsRegroupement.unrestrict_primary_key
          cr = creneau.add_regroupement regroupement_id: params[:regroupement_id]
          cr.update semaines_de_presence: params[:semaines_de_presence_regroupement] if params[:semaines_de_presence_regroupement]
          CreneauEmploiDuTempsRegroupement.restrict_primary_key
        end

        if params[:salle_id]
          CreneauEmploiDuTempsSalle.unrestrict_primary_key
          cs = creneau.add_salle salle_id: params[:salle_id]
          cs.update semaines_de_presence: params[:semaines_de_presence_salle] if params[:semaines_de_presence_salle]
          CreneauEmploiDuTempsSalle.restrict_primary_key
        end

        creneau
      end

      desc 'modifie un créneau'
      params {
        requires :id, type: Integer

        optional :matiere_id
        optional :regroupement_id
        optional :previous_regroupement_id
        optional :heure_debut, type: Time
        optional :heure_fin, type: Time
        optional :salle_id
        optional :semaines_de_presence_regroupement, type: Fixnum
        optional :semaines_de_presence_enseignant, type: Fixnum
        optional :semaines_de_presence_salle, type: Fixnum
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
          creneau.matiere_id = params[:matiere_id] if params[:matiere_id]

          creneau.save

          if params[:semaines_de_presence_enseignant]
            ce = CreneauEmploiDuTempsEnseignant.where( enseignant_id: user.uid ).where( creneau_emploi_du_temps_id: params[:id] )
            ce.update semaines_de_presence: params[:semaines_de_presence_enseignant]
          end

          if params[:regroupement_id]
            if CreneauEmploiDuTempsRegroupement
                .where( creneau_emploi_du_temps_id: params[:id] )
                .where( regroupement_id: params[:regroupement_id] ).count < 1
              CreneauEmploiDuTempsRegroupement.unrestrict_primary_key

              # 1. first remove previous créneau-regroupement association
              previous_creneau_regroupement = CreneauEmploiDuTemps.last.regroupements.select { |cr| cr.regroupement_id == params[:previous_regroupement_id] }.first
              previous_creneau_regroupement.destroy unless previous_creneau_regroupement.nil?

              # 2. create the new one
              cr = creneau.add_regroupement regroupement_id: params[:regroupement_id]
              cr.update semaines_de_presence: params[:semaines_de_presence_regroupement] if params[:semaines_de_presence_regroupement]

              CreneauEmploiDuTempsRegroupement.restrict_primary_key
            end
          end

          if params[:salle_id]
            CreneauEmploiDuTempsSalle.unrestrict_primary_key
            cs = creneau.add_salle salle_id: params[:salle_id]
            cs.update semaines_de_presence: params[:semaines_de_presence_salle] if params[:semaines_de_presence_salle]
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
