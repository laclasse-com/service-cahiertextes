# -*- coding: utf-8 -*-

class Etablissement < Sequel::Model( :etablissements )
  def statistiques_classes
    Annuaire
      .get_etablissement( values[:UAI] )['classes']
      .map do |classe|
      cdt = CahierDeTextes.where( regroupement_id: classe['id'] ).first
      cdt = CahierDeTextes.create( regroupement_id: classe[ 'id' ] ) if cdt.nil?
      cdt.statistiques
    end
  end

  def statistiques_enseignants
    Annuaire
      .get_etablissement( values[:UAI] )['enseignants']
      .map do |enseignant|

      { enseignant_id: enseignant['id_ent'],
        classes: CreneauEmploiDuTempsRegroupement
          .join( :creneaux_emploi_du_temps_enseignants, creneau_emploi_du_temps_id: :creneau_emploi_du_temps_id )
          .where( enseignant_id: enseignant['id_ent'] )
          .select( :regroupement_id )
          .group_by( :regroupement_id )
          .map do |regroupement_id|
          { regroupement_id: regroupement_id.values[ :regroupement_id ],
            statistiques: (1..12).map do |month|
              stats = { month: month,
                filled: 0,
                validated: 0 }

              CreneauEmploiDuTempsEnseignant
                .join( :creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :creneau_emploi_du_temps_id )
                .where( enseignant_id: enseignant['id_ent'] )
                .where( regroupement_id: regroupement_id.values[ :regroupement_id ] )
                .each do |creneau|
                # TODO: prendre en compte les semaine_de_presence
                cours = Cours
                  .where( creneau_emploi_du_temps_id: creneau.creneau_emploi_du_temps_id )
                  .where( 'extract( month from date_cours ) = ' + month.to_s )
                  .where( deleted: false )

                # TODO: calcul total attendu
                stats[:filled] += cours.count
                stats[:validated] += cours.where( :date_validation ).count
              end

              stats
            end
          }
        end
      }
    end
  end

  def saisies_enseignant( enseignant_id )
    { enseignant_id: enseignant_id,
      saisies: (1..12).map do
        |month|
        
        Cours
          .where( enseignant_id: enseignant_id )
          .where( 'extract( month from date_cours ) = ' + month.to_s )
          .where( deleted: false )
          .map do
          |cours|
          devoir = Devoir.where(cours_id: cours.id).first
          devoir = -1 if devoir.nil?

          # TODO: tenir compte des semaines de présence
          { mois: month,
            classe_id: CreneauEmploiDuTempsRegroupement.where(creneau_emploi_du_temps_id: cours.creneau_emploi_du_temps_id).first.regroupement_id,
            matiere_id: CreneauEmploiDuTemps[ cours.creneau_emploi_du_temps_id ].matiere_id,
            cours: cours,
            devoir: devoir,
            valide: !cours.date_validation.nil? }
        end
      end.flatten
    }
  end

  def valide_enseignant!( enseignant_id )
    Cours
      .where(enseignant_id: enseignant_id)
      .where('date_validation IS NULL')
      .where( deleted: false )
      .update( date_validation: Time.now )
  end
end
