# coding: utf-8
# frozen_string_literal: true

module DataManagement
    module EmploiDuTemps
        module_function

        def get( debut, fin, groups_ids, subjects_ids, eleve_id )
            debut = Date.parse( debut ) if debut.is_a?( String )
            fin = Date.parse( fin ) if fin.is_a?( String )

            # Nota Bene: semainiers callés sur l'année civile
            query = Timeslot.where( group_id: groups_ids )
                            .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
                            .where( Sequel.lit( "`dtime` IS NULL OR DATE_FORMAT( dtime, '%Y-%m-%d') >= '#{fin}'" ) )

            query = query.where( subject_id: subjects_ids ) unless subjects_ids.nil?

            query.all
                 .map do |timeslot|
                ( debut .. fin ).select { |day| day.wday == timeslot.weekday && timeslot.active_weeks[day.cweek] == 1 }
                                .map do |day|
                    { group_id: timeslot.group_id,
                      timeslot_id: timeslot.id,
                      subject_id: timeslot.subject_id,
                      start_time: Time.new( day.year, day.month, day.mday, timeslot.start.hour, timeslot.start.min ).iso8601,
                      end_time: Time.new( day.year, day.month, day.mday, timeslot.end.hour, timeslot.end.min ).iso8601,
                      session: timeslot.session
                                       .select { |session| session[:dtime].nil? && session.date == day }
                                       .map do |session|
                            hsession = session.to_hash
                            hsession[:attachments] = session.attachments.map(&:to_hash)

                            hsession
                        end
                                       .first,
                      assignments: timeslot.assignments
                                           .select { |assignment| assignment[:dtime].nil? && assignment.date_due == day }
                                           .map do |assignment|
                            hassignment = assignment.to_hash
                            hassignment[:attachments] = assignment.attachments.map(&:to_hash)
                            hassignment[:assignment_type_description] = assignment.assignment_type.description

                            hassignment[:done] = assignment.done_by?( eleve_id ) unless eleve_id.nil?
                            hassignment[:rtime] = assignment.done_on_the( eleve_id ) if hassignment[:done]

                            hassignment
                        end }
                end
            end
                 .flatten
                 .compact
        end
    end
end
