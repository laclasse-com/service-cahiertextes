# -*- coding: utf-8 -*-

require 'date'

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

      # TODO
      user_id = 1

      # TODO
      regroupement_id = CreneauEmploiDuTempsRegroupement
        .select(:regroupement_id)
        .map { |r| r.regroupement_id }
        .sample

      CreneauEmploiDuTemps
        .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :id)
        .where( regroupement_id: regroupement_id)
        .map {
        |creneau|
        plage_debut = PlageHoraire[ creneau.debut ].debut
        plage_fin = PlageHoraire[ creneau.fin ].fin
        lundi = date_of_last 'monday' # FIXME: pas forcément un lundi ?
        jour = lundi + ( creneau.jour_de_la_semaine - 2)

        # TODO: test qu'il n'y a qu'un seul cahier de textes
        data = CahierDeTextes.where( regroupement_id: regroupement_id )
        # raise '/!\ Incohérence dans les cahier de textes !' unless data.count == 1
        cahier_de_textes = data.first

        data = Cours.where(creneau_emploi_du_temps_id: creneau.id).where(cahier_de_textes_id: cahier_de_textes.id )
        # raise '/!\ Incohérence dans les cours !' unless data.count == 1
        if data.first.nil?
          cours = {}
        else
          cours = data.first.to_hash # data.first.to_hash_complet
          cours[:ressources] = data.first.ressources
        end

        data = Devoir.where(cours_id: cours[:id]) if cours.key?( :id )
        if data.first.nil?
          devoirs = []
        else
          devoirs = data.map { |devoir|
            d = devoir.to_hash # data.first.to_hash_complet
            d[:ressources] = devoir.ressources
            d[:fait] = devoir.fait_par?( user_id )

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
      }.flatten
    end

  end
end
