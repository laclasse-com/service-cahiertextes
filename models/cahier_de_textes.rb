# -*- coding: utf-8 -*-

require_relative '../lib/utils/date_rentree'

class CahierDeTextes < Sequel::Model( :cahiers_de_textes )
  one_to_many :cours, class: :Cours

  def creneaux_emploi_du_temps
    CreneauEmploiDuTemps.where( regroupement_id: regroupement_id )
                        .where( deleted: false )
                        .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                        .all
  end

  def statistiques
    cours = Cours.where( cahier_de_textes_id: id )
                 .where( Sequel.~( Sequel.qualify( "cours", "deleted" ) ) )
                 .where( Sequel.lit( "DATE_FORMAT( cours.date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )

    creneaux = creneaux_emploi_du_temps

    { regroupement_id: regroupement_id,
      creneaux_emploi_du_temps: { vides: creneaux.select { |creneau| creneau.cours.empty? && creneau.devoirs.empty? }.map( &:id ),
                                  pleins: creneaux.select { |creneau| !creneau.cours.empty? || !creneau.devoirs.empty? }.map( &:id ) },
      matieres: cours.association_join( :creneau_emploi_du_temps )
                     .select( :matiere_id )
                     .group_by( :matiere_id )
                     .map do |record|
        { matiere_id: record.values[ :matiere_id ],
          mois: (1..12).map do |month|
            tmp_cours = cours.association_join( :creneau_emploi_du_temps )
                             .where( Sequel.&( Sequel.qualify( "creneau_emploi_du_temps", "deleted"), false ) )
                             .where( matiere_id: record.values[:matiere_id] )
                             .where( Sequel.lit( "extract( month from date_cours ) = #{month}" ) )

            { mois: month,
              filled: tmp_cours.count,
              validated: tmp_cours.where( :date_validation ).count }
          end }
      end }
  end
end
