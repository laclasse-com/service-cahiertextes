require_relative '../lib/utils'

class TextBook < Sequel::Model( :textbooks )
  one_to_many :sessions

  def timeslots
      Timeslot.where( group_id: group_id )
              .where( deleted: false )
              .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
              .all
  end

  def statistics
      { group_id: group_id,
        timeslots: { empty: timeslots.select { |timeslot| timeslot.sessions.empty? && timeslot.assignments.empty? }.map( &:id ),
                     filled: timeslots.select { |timeslot| !timeslot.sessions.empty? || !timeslot.assignments.empty? }.map( &:id ) } }
  end
end
