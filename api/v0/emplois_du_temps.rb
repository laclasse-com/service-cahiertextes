# -*- coding: utf-8 -*-

require_relative '../../lib/annuaire'

module CahierDeTextesAPI
  module V0
    class EmploisDuTempsAPI < Grape::API

      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
        requires :debut, type: Date
        requires :fin, type: Date
        optional :uai
      }
      get '/du/:debut/au/:fin' do
        # if # ( user.is?( 'ENS' ) ||
        #    #     user.is?( 'ELV' ) ||
        #    #     user.is?( 'DIR' ) ) &&
        #   user.methods.include? :classes

        params[:debut] = Date.parse( params[:debut].iso8601 )
        params[:fin] = Date.parse( params[:fin].iso8601 )

        # FIXME
        regroupements_ids = Annuaire.get_user_regroupements( user.uid )['classes'].reject {
          |classe|
          classe['etablissement_code'] != params[:uai] if params[:uai]
        }.map {
          |classe|
          classe['classe_id']
        }.uniq

        CreneauEmploiDuTemps
          .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :id)
          .where( regroupement_id: regroupements_ids )
          .map {
          |creneau|
          plage_debut = PlageHoraire[ creneau.debut ].debut
          plage_fin = PlageHoraire[ creneau.fin ].fin

          # 1. récupération du cahier de textes
          cahier_de_textes = CahierDeTextes.where( regroupement_id: creneau[:regroupement_id] ).first

          ( params[:debut] .. params[:fin] )
            .reject { |day| day.wday != creneau.jour_de_la_semaine }
            .map { |jour|
            cours = {}
            devoirs = []

            # 2. récupération des cours
            Cours.where( creneau_emploi_du_temps_id: creneau.id )
              .where( cahier_de_textes_id: cahier_de_textes.id )
              .where( date_cours: jour ).map {
              |le_cours|

              cours = le_cours.to_hash
              cours[:ressources] = le_cours.ressources

              devoirs = Devoir.where( cours_id: cours[:id] ).all.map {
                |devoir|
                hstart = PlageHoraire[ CreneauEmploiDuTemps[ devoir.creneau_emploi_du_temps_id ].debut ].debut
                hend = PlageHoraire[ CreneauEmploiDuTemps[ devoir.creneau_emploi_du_temps_id ].fin ].fin
                d = devoir.to_hash
                d[:ressources] = devoir.ressources
                d[:fait] = devoir.fait_par?( user.uid )
                d[:start] = Time.new( devoir.date_due.year, devoir.date_due.month, devoir.date_due.mday, hstart.hour, hstart.min ).iso8601
                d[:end] = Time.new( devoir.date_due.year, devoir.date_due.month, devoir.date_due.mday, hend.hour, hend.min ).iso8601

                d
              }
            }

            {  cahier_de_textes_id: cahier_de_textes.id,
               regroupement_id: cahier_de_textes.regroupement_id,
               creneau_emploi_du_temps_id: creneau.id,
               matiere_id: creneau.matiere_id,
               start: Time.new( jour.year, jour.month, jour.mday, plage_debut.hour, plage_debut.min ).iso8601,
               end: Time.new( jour.year, jour.month, jour.mday, plage_fin.hour, plage_fin.min ).iso8601,
               cours: cours,
               devoirs: devoirs
            }
          }
        }.flatten

        # else
        #    []
        # end
      end

    end
  end
end
