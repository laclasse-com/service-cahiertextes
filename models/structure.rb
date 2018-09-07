require_relative '../lib/utils'

class Structure < Sequel::Model( :structures )
  one_to_many :timeslots
  one_to_many :imports
  one_to_many :locations
  one_to_many :matchables

  def statistics_groups
    etab = JSON.parse( RestClient::Request.execute( method: :get,
                                                    url: "#{URL_ENT}/api/structures/#{values[:UAI]}",
                                                    user: ANNUAIRE[:app_id],
                                                    password: ANNUAIRE[:api_key] ) )

    etab['groups'].map do |group|
      textbook = TextBook[ group_id: group['id'] ]
      textbook = TextBook.create( ctime: Time.now, group_id: group['id'] ) if textbook.nil?
      textbook.statistics
    end
  end

  def statistics_authors
    JSON.parse( RestClient::Request.execute( method: :get,
                                             url: "#{URL_ENT}/api/profiles/?type=ENS&structure_id=#{values[:UAI]}",
                                             user: ANNUAIRE[:app_id],
                                             password: ANNUAIRE[:api_key] ) )
        .map do |author|
      { author_id: author['user_id'],
        classes: sessions_author( author['user_id'] )[:sessions]
          .group_by { |s| s[:group_id] }
          .map do |group_id, group_sessions|
          { group_id: group_id,
            statistics: group_sessions
              .group_by { |rs| rs[:mois] }
              .map do |mois, mois_sessions|
              { month: mois,
                validated: mois_sessions.count { |s| s[:valide] },
                filled: mois_sessions.count }
            end }
        end }
    end
  end

  def sessions_author( author_id )
    { author_id: author_id,
      sessions: Session.where( author_id: author_id )
                    .where( deleted: false )
                    .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
                    .map do |session|
        assignments = Assignment.where(session_id: session.id)
                        .where( deleted: false )
                        .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
                        .all
        timeslot = Timeslot[session.timeslot_id]

        { month: session.date.month,
          group_id: timeslot.group_id,
          subject_id: timeslot.subject_id,
          sessions: sessions,
          assignments: assignments,
          valide: !session.vtime.nil? }
      end }
  end

  # def merge_all_twin_timeslots( truly_destroy = false )
  #   merged_twins = []
  #   timeslots_dataset.where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
  #                                   .all
  #                                   .each do |timeslot|
  #     next if merged_twins.include?( timeslot.id )

  #     merged_twins += timeslot.merge_and_destroy_twins( truly_destroy )
  #     merged_twins.flatten!
  #   end

  #   merged_twins
  # end
end
