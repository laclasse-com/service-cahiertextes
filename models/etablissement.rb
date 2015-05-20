# -*- coding: utf-8 -*-

class Etablissement < Sequel::Model( :etablissements )
  def statistiques_classes
    AnnuaireWrapper::Etablissement.get( values[:UAI] )['classes']
      .map do |classe|
      cdt = CahierDeTextes.where( regroupement_id: classe['id'] ).first
      cdt = CahierDeTextes.create( date_creation: Time.now,
                                   regroupement_id: classe[ 'id' ] ) if cdt.nil?
      cdt.statistiques
    end
  end

  def statistiques_enseignants
    AnnuaireWrapper::Etablissement
      .get( values[:UAI] )['enseignants']
      .map do |enseignant|
      { enseignant_id: enseignant['id_ent'],
        classes: saisies_enseignant( enseignant['id_ent'] )[:saisies]
          .group_by { |s| s[:regroupement_id] }
          .map do |regroupement_id, regroupement_saisies|
          { regroupement_id: regroupement_id,
            statistiques: regroupement_saisies
              .group_by { |rs| rs[:mois] }
              .map do |mois, mois_saisies|
              { month: mois,
                validated: mois_saisies.count { |s| s[:valide] },
                filled: mois_saisies.count }
            end }
        end }
    end
  end

  def saisies_enseignant( enseignant_id )
    { enseignant_id: enseignant_id,
      saisies: (1..12).map do |month|
        Cours
          .where( enseignant_id: enseignant_id )
          .where( 'extract( month from date_cours ) = ' + month.to_s )
          .where( deleted: false )
          .map do |cours|
          devoir = Devoir.where(cours_id: cours.id)

          { mois: month,
            regroupement_id: CreneauEmploiDuTempsRegroupement
              .where( creneau_emploi_du_temps_id: cours.creneau_emploi_du_temps_id )
              .first
              .regroupement_id,
            matiere_id: CreneauEmploiDuTemps[ cours.creneau_emploi_du_temps_id ].matiere_id,
            cours: cours,
            devoirs: devoir,
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
