# -*- coding: utf-8 -*-

module DataManagement
  module EmploiDuTemps
    module_function

    def get( debut, fin, groups_ids, subjects_ids, eleve_id )
      debut = Date.parse( debut ) if debut.is_a?( String )
      fin = Date.parse( fin ) if fin.is_a?( String )

      # Nota Bene: semainiers callés sur l'année civile
      query = CreneauEmploiDuTemps.where( regroupement_id: groups_ids )
                                  .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                                  .where( Sequel.lit( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( date_suppression, '%Y-%m-%d') >= '#{fin}')" ) )

      query = query.where( matiere_id: subjects_ids ) unless subjects_ids.nil?

      query.all
           .map do |creneau|
        ( debut .. fin ).select { |day| day.wday == creneau.jour_de_la_semaine && creneau.semainier[ day.cweek ] == 1 }
                        .map do |day|
          { regroupement_id: creneau.regroupement_id,
            creneau_emploi_du_temps_id: creneau.id,
            matiere_id: creneau.matiere_id,
            start: Time.new( day.year, day.month, day.mday, creneau.debut.hour, creneau.debut.min ).iso8601,
            end: Time.new( day.year, day.month, day.mday, creneau.fin.hour, creneau.fin.min ).iso8601,
            cours: creneau.cours
                          .select { |cours| cours[:deleted] == false && cours.date_cours == day }
                          .map do |cours|
              hcours = cours.to_hash
              hcours[:ressources] = cours.ressources.map(&:to_hash)

              hcours
            end
                          .first,
            devoirs: creneau.devoirs
                            .select { |devoir| devoir[:deleted] == false && devoir.date_due == day }
                            .map do |devoir|
              hdevoir = devoir.to_hash
              hdevoir[:ressources] = devoir.ressources.map(&:to_hash)
              hdevoir[:type_devoir_description] = devoir.type_devoir.description

              hdevoir[:fait] = devoir.fait_par?( eleve_id ) unless eleve_id.nil?
              hdevoir[:date_fait] = devoir.fait_le( eleve_id ) if hdevoir[:fait]

              hdevoir
            end }
        end
      end
           .flatten
           .compact
    end
  end
end
