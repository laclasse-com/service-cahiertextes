# -*- coding: utf-8 -*-

class Etablissement < Sequel::Model( :etablissements )
  def statistiques_classes
    CahierDeTextes.map {
      |cahier_de_textes|
      cahier_de_textes.statistiques
    }
  end

  def statistiques_enseignants
    # FIXME: get this from actual etablissement
    enseignants_ids = Cours.select( :enseignant_id ).group_by( :enseignant_id ).all.map {
      |cours|
      cours.values[ :enseignant_id ]
    }

    enseignants_ids.map do
      |enseignant_id|
      { enseignant_id: enseignant_id,
        classes: CreneauEmploiDuTempsRegroupement
          .join( :creneaux_emploi_du_temps_enseignants, creneau_emploi_du_temps_id: :creneau_emploi_du_temps_id )
          .select( :regroupement_id ).where( enseignant_id: enseignant_id )
          .group_by( :regroupement_id )
          .map { |regroupement_id|
          {
            regroupement: regroupement_id.values[ :regroupement_id ],
            statistiques: (1..12).map do
              |month|
              stats = { month: month, filled: 0, validated: 0 }

              CreneauEmploiDuTempsEnseignant
                .join( :creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :creneau_emploi_du_temps_id )
                .where( enseignant_id: enseignant_id )
                .where( regroupement_id: regroupement_id.values[ :regroupement_id ] )
                .map do
                |creneau|
                # TODO: prendre en compte les semaine_de_presence
                cours = Cours
                  .where( creneau_emploi_du_temps_id: creneau.creneau_emploi_du_temps_id )
                  .where( 'extract( month from date_cours ) = ' + month.to_s )

                # TODO: calcul total attendu
                { filled: cours.count,
                  validated: cours.where( :date_validation ).count
                }
              end.each {
                |values|
                [:filled, :validated].each {
                  |key|
                  stats[ key ] += values[ key ]
                }
              }

              stats
            end
          }
        }
      }
    end
  end

  def saisies_enseignant( enseignant_id )
    { enseignant_id: enseignant_id,
      saisies:
      (1..12).map do
        |month|

        Cours.where( enseignant_id: enseignant_id ).where( 'extract( month from date_cours ) = ' + month.to_s )
          .map do
          |cours|
          devoir = Devoir.where(cours_id: cours.id).first
          devoir_id = devoir.nil? ? -1 : devoir.id
          devoir_contenu = devoir.nil? ? -1 : devoir.contenu

          {                     # TODO: tenir compte des semaines de présence
            classe_id: CreneauEmploiDuTempsRegroupement.where(creneau_emploi_du_temps_id: cours.creneau_emploi_du_temps_id).first.regroupement_id,
            matiere_id: CreneauEmploiDuTemps[ cours.creneau_emploi_du_temps_id ].matiere_id,
            cours_id: cours.id,
            cours: cours.contenu,
            devoir_id: devoir_id,
            devoir: devoir_contenu,
            valide: !cours.date_validation.nil?
          }
        end
      end
    }
  end

  def valide_enseignant!( enseignant_id )
    Cours.where(enseignant_id: enseignant_id).where('date_validation IS NULL').update(date_validation: Time.now)
  end
end
