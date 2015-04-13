# -*- coding: utf-8 -*-

class CahierDeTextes < Sequel::Model( :cahiers_de_textes )
  one_to_many :cours, class: :Cours

  def statistiques
    cours = Cours
            .where( cahier_de_textes_id: id )
            .where( cours__deleted: false )

    { regroupement_id: regroupement_id,
      matieres: cours
        .association_join( :creneau_emploi_du_temps )
        .select( :matiere_id )
        .group_by( :matiere_id )
        .map do |record|
        { matiere_id: record.values[ :matiere_id ],
          mois: (1..12).map do |month|
            tmp_cours = cours
                        .association_join( :creneau_emploi_du_temps )
                        .where( matiere_id: record.values[:matiere_id] )
                        .where( 'extract( month from date_cours ) = ' + month.to_s )

            { mois: month,
              filled: tmp_cours.count,
              validated: tmp_cours.where( :date_validation ).count }
          end
        }
      end
    }
  end
end
