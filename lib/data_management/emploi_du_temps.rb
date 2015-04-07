# -*- coding: utf-8 -*-

module DataManagement
  module EmploiDuTemps
    module_function

    def get( debut, fin, regroupements_ids, eleve_id )
      # Nota Bene: creneau[:semaines_de_presence][ 1 ] == première semaine de janvier
      CreneauEmploiDuTemps
        .association_join( :enseignants )
        .association_join( :regroupements )
        .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{1.year.ago}'" )
        .where( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( date_suppression, '%Y-%m-%d') >= '#{fin}')" )
        .where( regroupement_id: regroupements_ids )
        .all
        .map do |creneau|
        ( debut .. fin )
          .select { |day| day.wday == creneau.jour_de_la_semaine } # only the same weekday as the creneau
          .map do |jour|
            if creneau[:semaines_de_presence][ jour.cweek ] == 1
              cahier_de_textes = CahierDeTextes.where( regroupement_id: creneau[:regroupement_id] ).first
              cahier_de_textes = CahierDeTextes.create( date_creation: Time.now,
                                                        regroupement_id: creneau[:regroupement_id] ) if cahier_de_textes.nil?

              { regroupement_id: creneau[ :regroupement_id ],
                enseignant_id: creneau[ :enseignant_id ],
                creneau_emploi_du_temps_id: creneau.id,
                matiere_id: creneau.matiere_id,
                cahier_de_textes_id: cahier_de_textes.id,  # utilisé lors de la création d'un cours côté client
                start: Time.new( jour.year,
                                 jour.month,
                                 jour.mday,
                                 creneau.plage_horaire_debut.debut.hour,
                                 creneau.plage_horaire_debut.debut.min ).iso8601,
                end: Time.new( jour.year,
                               jour.month,
                               jour.mday,
                               creneau.plage_horaire_fin.fin.hour,
                               creneau.plage_horaire_fin.fin.min ).iso8601,
                cours: creneau.cours.select { |cours| cours[:deleted] == false && cours.date_cours == jour }
                                    .map do |cours|
                  hcours = cours.to_hash
                  hcours[:ressources] = cours.ressources.map { |rsrc| rsrc.to_hash }

                  hcours
                end
                                    .first,
                devoirs: creneau.devoirs.select { |devoir| devoir[:deleted] == false && devoir.date_due == jour }
                                        .map do |devoir|
                  hdevoir = devoir.to_hash
                  hdevoir[:ressources] = devoir.ressources.map { |rsrc| rsrc.to_hash }
                  hdevoir[:type_devoir_description] = devoir.type_devoir.description

                  hdevoir[:fait] = devoir.fait_par?( eleve_id ) unless eleve_id.nil?

                  hdevoir
                end
              }
            else
              next
            end
          end
      end
        .flatten
        .compact
    end
  end
end
