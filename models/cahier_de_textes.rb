# -*- coding: utf-8 -*-

class CahierDeTextes < Sequel::Model( :cahiers_de_textes )
  def statistiques
    cours = Cours
      .where( cahier_de_textes_id: id )
      .where( :date_cours )
      .where( deleted: false )

    {
      regroupement_id: regroupement_id,
      matieres:
      cours.join(:creneaux_emploi_du_temps, id: :creneau_emploi_du_temps_id).select(:matiere_id).group_by(:matiere_id).map do
        |record|
        {
          matiere_id: record.values[:matiere_id],
          mois:
          (1..12).map do
            |month|
            tmp_cours = cours.join(:creneaux_emploi_du_temps, id: :creneau_emploi_du_temps_id).where(matiere_id: record.values[:matiere_id]).where( 'extract( month from date_cours ) = ' + month.to_s )

            {
              mois: month,
              filled: tmp_cours.count,
              validated: tmp_cours.where( :date_validation ).count
            }
          end
        }
      end,
    }
  end

  # Valide tout un cahier de texte
  def valide!
    Cours
      .where( cahier_de_textes_id: id )
      .where( 'date_validation IS NULL' )
      .where( deleted: false )
      .update( date_validation: Time.now )
  end
end
