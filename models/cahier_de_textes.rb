# -*- coding: utf-8 -*-

class CahierDeTextes < Sequel::Model( :cahiers_de_textes )
  def statistiques
    cours = Cours.where(cahier_de_textes_id: id).where(:date_cours)
    {
      regroupement_id: regroupement_id,
      filled: cours.count,
      validated: cours.where( :date_validation ).count,
      par_mois: (1..12).map do
        |month|

        tmp_cours = cours.where( 'extract( month from date_cours ) = ' + month.to_s )
        {
          filled: tmp_cours.count,
          validated: tmp_cours.where( :date_validation ).count
            # matiere_id: CreneauEmploiDuTemps[ cours.creneau_emploi_du_temps_id ].matiere_id,
        }
      end
    }
  end

  def contenu( debut, fin )
    # TODO: return the content of this Cahier de textes during the given dates interval
    {}
  end
end
