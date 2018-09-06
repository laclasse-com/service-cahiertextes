require_relative '../lib/utils/date_rentree'

class Structure < Sequel::Model( :structures )
  one_to_many :timeslots
  one_to_many :imports
  one_to_many :locations
  one_to_many :matchables

  def statistiques_regroupements
    etab = JSON.parse( RestClient::Request.execute( method: :get,
                                                    url: "#{URL_ENT}/api/structures/#{values[:UAI]}",
                                                    user: ANNUAIRE[:app_id],
                                                    password: ANNUAIRE[:api_key] ) )

    etab['groups'].map do |group|
      textbook = TextBook[ regroupement_id: group['id'] ]
      textbook = TextBook.create( date_creation: Time.now, regroupement_id: group['id'] ) if textbook.nil?
      textbook.statistiques
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
        timeslot = Timeslot[cours.timeslot_id]

        { mois: cours.date_cours.month,
          regroupement_id: timeslot.group_id,
          matiere_id: timeslot.subject_id,
          cours: cours,
          devoirs: devoirs,
          valide: !cours.date_validation.nil? }
      end }
  end

  # def merge_all_twin_timeslotx( truly_destroy = false )
  #   merged_twins = []
  #   timeslotx_emploi_du_temps_dataset.where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
  #                                   .all
  #                                   .each do |timeslot|
  #     next if merged_twins.include?( timeslot.id )

  #     merged_twins += timeslot.merge_and_destroy_twins( truly_destroy )
  #     merged_twins.flatten!
  #   end

  #   merged_twins
  # end
end
