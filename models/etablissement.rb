# -*- coding: utf-8 -*-

class Etablissement < Sequel::Model( :etablissements )
  def statistiques_classes
    Annuaire
      .get_etablissement( values[:UAI] )['classes']
      .map do |classe|
      cdt = CahierDeTextes.where( regroupement_id: classe['id'] ).first
      cdt = CahierDeTextes.create( date_creation: Time.now,
                                   regroupement_id: classe[ 'id' ] ) if cdt.nil?
      cdt.statistiques
    end
  end

  def statistiques_enseignants
    Annuaire
      .get_etablissement( values[:UAI] )['enseignants']
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
                                       validated: mois_saisies.select { |s| s[:valide] }.count,
                                       filled: mois_saisies.count }
                                   end }
                 end }
    end
  end

  def saisies_enseignant( enseignant_id )
    date_rentree = Date.parse( "#{Date.today.month > 8 ? Date.today.year : Date.today.year - 1}-09-01" )

    { enseignant_id: enseignant_id,
      saisies: Cours
        .where( enseignant_id: enseignant_id )
        .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{date_rentree}'" )
        .where( deleted: false )
        .map do
        |cours|

                 devoirs = Devoir.where(cours_id: cours.id)
                 creneau = CreneauEmploiDuTemps[ cours.creneau_emploi_du_temps_id ]

                 { mois: cours.date_cours.month,
                   regroupement_id: creneau.regroupements.first.regroupement_id,
                   matiere_id: creneau.matiere_id,
                   cours: cours,
                   devoirs: devoirs,
                   valide: !cours.date_validation.nil? }
               end
    }
  end

  def valide_enseignant!( enseignant_id )
    date_rentree = Date.parse( "#{Date.today.month > 8 ? Date.today.year : Date.today.year - 1}-09-01" )
    Cours
      .where(enseignant_id: enseignant_id)
      .where( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{date_rentree}'" )
      .where('date_validation IS NULL')
      .where( deleted: false )
      .update( date_validation: Time.now )
  end
end
