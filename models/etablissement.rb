# -*- coding: utf-8 -*-

require_relative '../lib/utils/date_rentree'

class Etablissement < Sequel::Model( :etablissements )
  one_to_many :creneaux_emploi_du_temps, class: :CreneauEmploiDuTemps
  one_to_many :imports

  def statistiques_classes
    AnnuaireWrapper::Etablissement
      .get( values[:UAI] )['classes']
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
          .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{Utils.date_rentree}'" )
          .where( 'extract( month from date_cours ) = ' + month.to_s )
          .where( deleted: false )
          .map do |cours|
          devoirs = Devoir.where(cours_id: cours.id)
          creneau = CreneauEmploiDuTemps[ cours.creneau_emploi_du_temps_id ]

          { mois: month,
            regroupement_id: creneau.regroupements.first.regroupement_id,
            matiere_id: creneau.matiere_id,
            cours: cours,
            devoirs: devoirs,
            valide: !cours.date_validation.nil? }
        end
      end.flatten
    }
  end

  def valide_enseignant!( enseignant_id )
    Cours
      .where(enseignant_id: enseignant_id)
      .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{Utils.date_rentree}'" )
      .where('date_validation IS NULL')
      .where( deleted: false )
      .update( date_validation: Time.now )
  end
end
