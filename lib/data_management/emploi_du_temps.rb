# -*- coding: utf-8 -*-

module DataManagement
  module EmploiDuTemps
    module_function

    def get( debut, fin, regroupements_ids, profil_type, eleve_id )
      # Nota Bene: semainiers callés sur l'année civile
      emploi_du_temps = CreneauEmploiDuTemps.association_join( :regroupements, :enseignants )
                                            .select_append( :regroupements__semaines_de_presence___semainier_regroupement )
                                            .select_append( :enseignants__semaines_de_presence___semainier_enseignant )
                                            .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{1.year.ago}'" )
                                            .where( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( date_suppression, '%Y-%m-%d') >= '#{fin}')" )
                                            .where( regroupement_id: regroupements_ids )
                                            .all
                                            .map do |creneau|
        ( debut .. fin ).select { |day| day.wday == creneau.jour_de_la_semaine && creneau[:semainier_regroupement][ day.cweek ] == 1 }
                        .map do |day|
          { regroupement_id: creneau[ :regroupement_id ],
            enseignant_id: creneau[ :enseignant_id ],
            creneau_emploi_du_temps_id: creneau.id,
            matiere_id: creneau.matiere_id,
            start: Time.new( day.year, day.month, day.mday, creneau.plage_horaire_debut.debut.hour, creneau.plage_horaire_debut.debut.min ).iso8601,
            end: Time.new( day.year, day.month, day.mday, creneau.plage_horaire_fin.fin.hour, creneau.plage_horaire_fin.fin.min ).iso8601,
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

              hdevoir
            end }
        end
      end
                                            .flatten
                                            .compact

      emploi_du_temps = emploi_du_temps.each { |c| c.delete :enseignant_id }.uniq if %w(ELV TUT).include? profil_type

      emploi_du_temps
    end

    def ical( debut, fin, regroupements_ids, profil_type, eleve_id )
      ical = Icalendar::Calendar.new

      get( debut, fin, regroupements_ids, profil_type, eleve_id )
        .each do |creneau|
        ical.event do |e|
          # [:regroupement_id, :enseignant_id, :creneau_emploi_du_temps_id, :matiere_id, :cahier_de_textes_id, :start, :end, :cours, :devoirs]
          e.dtstart = DateTime.parse( creneau[:start] )
          e.dtend = DateTime.parse( creneau[:end] )
          e.summary = "#{creneau[:regroupement_id]} - #{creneau[:matiere_id]}"
          e.description = creneau[:cours][:contenu] unless creneau[:cours].nil?
          # e.created = DateTime.parse( creneau[:date_creation] )
          # e.last_modified = DateTime.parse( creneau[:date_modification] )
        end
      end

      ical.publish

      ical.to_ical
    end
  end
end
