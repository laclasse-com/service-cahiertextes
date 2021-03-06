require_relative '../lib/utils/date_rentree'

class Etablissement < Sequel::Model( :etablissements )
  one_to_many :creneaux_emploi_du_temps, class: :CreneauEmploiDuTemps
  one_to_many :imports
  one_to_many :salles
  one_to_many :matchables

  def statistiques_regroupements
    etab = JSON.parse( RestClient::Request.execute( method: :get,
                                                    url: "#{URL_ENT}/api/structures/#{values[:UAI]}",
                                                    user: ANNUAIRE[:app_id],
                                                    password: ANNUAIRE[:api_key] ) )

    etab['groups'].map do |group|
      cdt = CahierDeTextes[ regroupement_id: group['id'] ]
      cdt = CahierDeTextes.create( date_creation: Time.now, regroupement_id: group['id'] ) if cdt.nil?
      cdt.statistiques
    end
  end

  def statistiques_enseignants
    JSON.parse( RestClient::Request.execute( method: :get,
                                             url: "#{URL_ENT}/api/profiles/?type=ENS&structure_id=#{values[:UAI]}",
                                             user: ANNUAIRE[:app_id],
                                             password: ANNUAIRE[:api_key] ) )
        .map do |enseignant|
      { enseignant_id: enseignant['user_id'],
        classes: saisies_enseignant( enseignant['user_id'] )[:saisies]
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
      saisies: Cours.where( enseignant_id: enseignant_id )
                    .where( deleted: false )
                    .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                    .map do |cours|
        devoirs = Devoir.where(cours_id: cours.id)
                        .where( deleted: false )
                        .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                        .all
        creneau = CreneauEmploiDuTemps[cours.creneau_emploi_du_temps_id]

        { mois: cours.date_cours.month,
          regroupement_id: creneau.regroupement_id,
          matiere_id: creneau.matiere_id,
          cours: cours,
          devoirs: devoirs,
          valide: !cours.date_validation.nil? }
      end }
  end

  # def merge_all_twin_creneaux( truly_destroy = false )
  #   merged_twins = []
  #   creneaux_emploi_du_temps_dataset.where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
  #                                   .all
  #                                   .each do |creneau|
  #     next if merged_twins.include?( creneau.id )

  #     merged_twins += creneau.merge_and_destroy_twins( truly_destroy )
  #     merged_twins.flatten!
  #   end

  #   merged_twins
  # end
end
