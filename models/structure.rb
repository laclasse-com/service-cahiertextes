require_relative '../lib/utils/date_rentree'

class Structure < Sequel::Model( :structures )
  one_to_many :timeslots
  one_to_many :imports
  one_to_many :locations
  one_to_many :matchables

  def statistiques_groups
    etab = JSON.parse( RestClient::Request.execute( method: :get,
                                                    url: "#{URL_ENT}/api/structures/#{values[:UAI]}",
                                                    user: ANNUAIRE[:app_id],
                                                    password: ANNUAIRE[:api_key] ) )

    etab['groups'].map do |group|
      textbook = TextBook[ group_id: group['id'] ]
      textbook = TextBook.create( ctime: Time.now, group_id: group['id'] ) if textbook.nil?
      textbook.statistiques
    end
  end

  def statistiques_authors
    JSON.parse( RestClient::Request.execute( method: :get,
                                             url: "#{URL_ENT}/api/profiles/?type=ENS&structure_id=#{values[:UAI]}",
                                             user: ANNUAIRE[:app_id],
                                             password: ANNUAIRE[:api_key] ) )
        .map do |author|
      { author_id: author['user_id'],
        classes: saisies_author( author['user_id'] )[:saisies]
          .group_by { |s| s[:group_id] }
          .map do |group_id, group_saisies|
          { group_id: group_id,
            statistiques: group_saisies
              .group_by { |rs| rs[:mois] }
              .map do |mois, mois_saisies|
              { month: mois,
                validated: mois_saisies.count { |s| s[:valide] },
                filled: mois_saisies.count }
            end }
        end }
    end
  end

  def saisies_author( author_id )
    { author_id: author_id,
      saisies: Session.where( author_id: author_id )
                    .where( deleted: false )
                    .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                    .map do |session|
        devoirs = Devoir.where(session_id: session.id)
                        .where( deleted: false )
                        .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                        .all
        timeslot = Timeslot[session.timeslot_id]

        { month: session.date.month,
          group_id: timeslot.group_id,
          subject_id: timeslot.subject_id,
          sessions: sessions,
          devoirs: devoirs,
          valide: !session.vtime.nil? }
      end }
  end

  # def merge_all_twin_timeslots( truly_destroy = false )
  #   merged_twins = []
  #   timeslots_dataset.where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
  #                                   .all
  #                                   .each do |timeslot|
  #     next if merged_twins.include?( timeslot.id )

  #     merged_twins += timeslot.merge_and_destroy_twins( truly_destroy )
  #     merged_twins.flatten!
  #   end

  #   merged_twins
  # end
end
