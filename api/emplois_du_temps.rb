# -*- coding: utf-8 -*-

require_relative '../lib/annuaire'

module CahierDeTextesAPI
   class EmploisDuTempsAPI < Grape::API

      helpers do
         def date_of_last(day)
            date  = Date.parse(day)
            delta = date <= Date.today ? 0 : 7
            date - delta
         end
      end

      desc 'emploi du temps de l\'utilisateur durant l\'intervalle de dates donné'
      params {
         optional :debut, type: Time
         optional :fin, type: Time
      }
      get  do
         # TODO: prendre en compte debut et fin

         if ( user.is?( 'ENS', user.ENTPersonStructRattachRNE ) ||
                user.is?( 'ELV', user.ENTPersonStructRattachRNE ) ||
                user.is?( 'DIR', user.ENTPersonStructRattachRNE ) ) &&
               ( user.methods.include? :classes )

            regroupements_ids = user.classes.map {
               |classe|
               classe['classe_id']
            }.uniq

            # FIXME: DEBUG
            regroupements_ids = [ 23, 24 ] if user.uid == 'VAA62559'

            CreneauEmploiDuTemps
            .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :id)
            .where( regroupement_id: regroupements_ids )
            .map {
               |creneau|
               plage_debut = PlageHoraire[ creneau.debut ].debut
               plage_fin = PlageHoraire[ creneau.fin ].fin

               lundi = date_of_last 'monday' # FIXME: pas forcément un lundi ?
               jour = lundi + ( creneau.jour_de_la_semaine - 2)

               # 1. récupération du cahier de textes
               data = CahierDeTextes.where( regroupement_id: creneau[ :regroupement_id ] )
               raise '/!\ Incohérence dans les cahier de textes !' unless data.count == 1
               cahier_de_textes = data.first

               # 2. récupération des cours
               data = Cours.where( creneau_emploi_du_temps_id: creneau.id )
                        .where( cahier_de_textes_id: cahier_de_textes.id )
                        .where( date_cours: jour ) # where( params[ :debut ] < :date_cours < params[ :fin ] )

               if data.count == 0

                  {
                     cahier_de_textes_id: cahier_de_textes.id,
                     regroupement_id: cahier_de_textes.regroupement_id,
                     creneau_emploi_du_temps_id: creneau.id,
                     matiere_id: creneau.matiere_id,
                     start: Time.new( jour.year, jour.month, jour.mday, plage_debut.hour, plage_debut.min ).iso8601,
                     end: Time.new( jour.year, jour.month, jour.mday, plage_fin.hour, plage_fin.min ).iso8601,
                     cours: {},
                     devoirs: []
                  }

               else

                  data.map { |le_cours|
                     cours = le_cours.to_hash
                     cours[:ressources] = le_cours.ressources

                     le_cours = Devoir.where( cours_id: cours[:id] ) if cours.key?( :id )
                     if le_cours.first.nil?
                        devoirs = []
                     else
                        devoirs = le_cours.map { |devoir|
                           hstart = PlageHoraire[ CreneauEmploiDuTemps[ devoir.creneau_emploi_du_temps_id ].debut ].debut
                           hend = PlageHoraire[ CreneauEmploiDuTemps[ devoir.creneau_emploi_du_temps_id ].fin ].fin
                           d = devoir.to_hash
                           d[:ressources] = devoir.ressources
                           d[:fait] = devoir.fait_par?( user.uid )
                           d[:start] = Time.new( devoir.date_due.year, devoir.date_due.month, devoir.date_due.mday, hstart.hour, hstart.min ).iso8601
                           d[:end] = Time.new( devoir.date_due.year, devoir.date_due.month, devoir.date_due.mday, hend.hour, hend.min ).iso8601

                           d
                        }
                     end

                     {
                        cahier_de_textes_id: cahier_de_textes.id,
                        regroupement_id: cahier_de_textes.regroupement_id,
                        creneau_emploi_du_temps_id: creneau.id,
                        matiere_id: creneau.matiere_id,
                        start: Time.new( jour.year, jour.month, jour.mday, plage_debut.hour, plage_debut.min ).iso8601,
                        end: Time.new( jour.year, jour.month, jour.mday, plage_fin.hour, plage_fin.min ).iso8601,
                        cours: cours,
                        devoirs: devoirs
                     }
                  }
               end

            }.flatten
         else
            []
         end
      end

   end
end
