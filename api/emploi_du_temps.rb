# -*- coding: utf-8 -*-

require 'date'

module CahierDeTextesAPI
  class EmploiDuTempsAPI < Grape::API

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
    get do
      # TODO
      dummy_regroupement_id = CreneauEmploiDuTempsRegroupement
        .select(:regroupement_id)
        .map {|r| r.regroupement_id}
        .sample

      CreneauEmploiDuTemps
        .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :id)
        .where( regroupement_id: dummy_regroupement_id)
        .map {
        |creneau|
        plage_debut = PlageHoraire[ creneau.debut ].debut
        plage_fin = PlageHoraire[ creneau.fin ].fin
        lundi = date_of_last 'monday' # FIXME: pas forcément un lundi ?
        jour = lundi + ( creneau.jour_de_la_semaine - 2)

        # TODO: test qu'il n'y a qu'un seul cahier de textes
        cahier_de_textes = CahierDeTextes.where( regroupement_id: dummy_regroupement_id ).first
        cours = Cours.where(creneau_emploi_du_temps_id: creneau.id).where(cahier_de_textes_id: cahier_de_textes.id ).first
        cours_id = cours.nil? ? -1 : cours.id
        devoir = Devoir.where(cours_id: cours_id).first unless cours_id == -1
        devoir_id = devoir.nil? ? -1 : devoir.id

        { matiere_id: creneau.matiere_id,
          start: Time.new( jour.year, jour.month, jour.mday, plage_debut.hour, plage_debut.min ).iso8601,
          end: Time.new( jour.year, jour.month, jour.mday, plage_fin.hour, plage_fin.min ).iso8601,
          cours_id: cours_id,
          devoir_id: devoir_id }
      }.flatten
    end

  end
end
