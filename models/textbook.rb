require_relative '../lib/utils/date_rentree'

class TextBook < Sequel::Model( :textbooks )
  one_to_many :cours, class: :Cours

  def creneaux_emploi_du_temps
    CreneauEmploiDuTemps.where( regroupement_id: group_id )
                        .where( deleted: false )
                        .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                        .all
  end

  def statistiques
    creneaux = creneaux_emploi_du_temps

    { group_id: group_id,
      creneaux_emploi_du_temps: { vides: creneaux.select { |creneau| creneau.cours.empty? && creneau.devoirs.empty? }.map( &:id ),
                                  pleins: creneaux.select { |creneau| !creneau.cours.empty? || !creneau.devoirs.empty? }.map( &:id ) } }
  end
end
