# coding: utf-8
def generate_test_data
    TextBook.all.each do |cahier_de_textes|
    12.times do |month|
      rand( 2..4 ).times do
        creneau = CreneauEmploiDuTempsEnseignant.all.sample

        cours = Cours.create( cahier_de_textes_id: cahier_de_textes.id,
                              creneau_emploi_du_temps_id: creneau.creneau_emploi_du_temps_id,
                              date_cours: "#{Time.now.year}-#{month + 1}-29",
                              contenu: 'Exemple de séquence pédagogique.',
                              enseignant_id: creneau.enseignant_id )
        STDERR.putc '.'

        next unless rand > 0.25
        creneau_emploi_du_temps = CreneauEmploiDuTemps.where(matiere_id: CreneauEmploiDuTemps[creneau.creneau_emploi_du_temps_id].matiere_id)
                                                      .where(jour_de_la_semaine: Date.tomorrow.wday)
                                                      .join(:creneaux_emploi_du_temps_enseignants, creneau_emploi_du_temps_id: :id)
                                                      .where(enseignant_id: cours.enseignant_id)
                                                      .first
        unless creneau_emploi_du_temps.nil?
          Devoir.create(cours_id: cours.id,
                        type_devoir_id: TypeDevoir.all.sample.id,
                        creneau_emploi_du_temps_id: creneau_emploi_du_temps.id,
                        date_due: Date.tomorrow,
                        contenu: 'Exemple de devoir.',
                        temps_estime: rand(0..120) )
        end
        STDERR.putc '.'
      end
    end
  end
  STDERR.puts
end
