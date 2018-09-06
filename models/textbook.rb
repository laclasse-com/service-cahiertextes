require_relative '../lib/utils/date_rentree'

class TextBook < Sequel::Model( :textbooks )
  one_to_many :cours, class: :Cours

  def timeslots
      Timeslot.where( group_id: group_id )
              .where( deleted: false )
              .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
              .all
  end

  def statistiques
      { group_id: group_id,
        timeslots: { vides: timeslots.select { |timeslot| timeslot.cours.empty? && timeslot.devoirs.empty? }.map( &:id ),
                     pleins: timeslots.select { |timeslot| !timeslot.cours.empty? || !timeslot.devoirs.empty? }.map( &:id ) } }
  end
end
