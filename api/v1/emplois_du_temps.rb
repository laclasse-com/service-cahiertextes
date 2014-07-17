# -*- coding: utf-8 -*-

require_relative '../../lib/annuaire'

module CahierDeTextesAPI
  module V1
    class EmploisDuTempsAPI < Grape::API

      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
        requires :debut, type: Date
        requires :fin, type: Date
        optional :uai
      }
      get '/du/:debut/au/:fin' do
        params[:debut] = Date.parse( params[:debut].iso8601 )
        params[:fin] = Date.parse( params[:fin].iso8601 )
        weeks =  ( params[:debut] .. params[:fin] ).map { |d| d.cweek }.uniq

        regroupements_ids = Annuaire.get_user_regroupements( user.uid )['classes']
                                    .reject { |classe| classe['etablissement_code'] != params[:uai] if params[:uai] }
                                    .map    { |classe| classe['classe_id'] }
                                    .uniq

        # FIXME: creneau[:semaines_de_presence][ 1 ] == première semaine de janvier ?
        # FIXME: Un creneau "deleted" ne doit pas empecher les saisies déjà effectuée d'apparaitre
        # Soit le créneau est marqué deleted ET les dates debut et fin sont antérieures à la date deleted
        # Soit le créneau n'est pas marqué deleted et pas de restriction sur les dates debut et fin
        CreneauEmploiDuTemps
          .association_join( :regroupements )
          .association_join( :enseignants )
          .where( "( (deleted = true and date_suppression <= '#{params[:fin]}') or (deleted = false) )" )
          .where( regroupement_id: regroupements_ids )
          .all
          .select do |creneau| weeks.reduce( true ) { |a, e| a && creneau[:semaines_de_presence][ e ] == 1 } end
          .map do |creneau|

          ( params[:debut] .. params[:fin] )
            .reject { |day| day.wday != creneau.jour_de_la_semaine }
            .map do
            |jour|

            { regroupement_id: creneau[ :regroupement_id ],
              enseignant_id: creneau[ :enseignant_id ],
              creneau_emploi_du_temps_id: creneau.id,
              matiere_id: creneau.matiere_id,
              cahier_de_textes_id: CahierDeTextes.where( regroupement_id: creneau[:regroupement_id] ).first.id,  # utilisé lors de la création d'un cours côté client
              start: Time.new( jour.year, jour.month, jour.mday, creneau.plage_horaire_debut.debut.hour, creneau.plage_horaire_debut.debut.min ).iso8601,
              end: Time.new( jour.year, jour.month, jour.mday, creneau.plage_horaire_fin.fin.hour, creneau.plage_horaire_fin.fin.min ).iso8601,
              cours:  creneau.cours.select do |cours|
                cours[:deleted] == false &&  cours.date_cours == jour
              end
                                   .map do |cours|
                hcours = cours.to_hash
                hcours[:ressources] = cours.ressources.map { |rsrc| rsrc.to_hash }

                hcours
              end
                                   .first,
              devoirs: creneau.devoirs.select do |devoir|
                devoir[:deleted] == false && devoir.date_due == jour
              end
                                      .map do |devoir|
                hdevoir = devoir.to_hash
                hdevoir[:ressources] = devoir.ressources.map { |rsrc| rsrc.to_hash }
                hdevoir[:type_devoir_description] = devoir.type_devoir.description
                hdevoir[:fait] = devoir.fait_par?( user.uid )

                hdevoir
              end
            }
          end
        end
          .flatten
      end
    end
  end
end
