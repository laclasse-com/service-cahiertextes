# coding: utf-8
module DataManagement
    module EmploiDuTemps
        module_function

        def get( debut, fin, groups_ids, subjects_ids, eleve_id )
            debut = Date.parse( debut ) if debut.is_a?( String )
            fin = Date.parse( fin ) if fin.is_a?( String )

            # Nota Bene: semainiers callés sur l'année civile
            query = Timeslot.where( group_id: groups_ids )
                            .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                            .where( Sequel.lit( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( date_suppression, '%Y-%m-%d') >= '#{fin}')" ) )

            query = query.where( matiere_id: subjects_ids ) unless subjects_ids.nil?

            query.all
                 .map do |timeslot|
                ( debut .. fin ).select { |day| day.wday == timeslot.weekday && timeslot.active_weeks[day.cweek] == 1 }
                                .map do |day|
                    { group_id: timeslot.group_id,
                      timeslot_id: timeslot.id,
                      subject_id: timeslot.subject_id,
                      start: Time.new( day.year, day.month, day.mday, timeslot.start.hour, timeslot.start.min ).iso8601,
                      end: Time.new( day.year, day.month, day.mday, timeslot.end.hour, timeslot.end.min ).iso8601,
                      session: timeslot.session
                                    .select { |session| session[:deleted] == false && session.date_session == day }
                                    .map do |session|
                          hsession = session.to_hash
                          hsession[:resources] = session.resources.map(&:to_hash)

                          hsession
                      end
                                    .first,
                      assignments: timeslot.assignments
                                      .select { |assignment| assignment[:deleted] == false && assignment.date_due == day }
                                      .map do |assignment|
                          hassignment = assignment.to_hash
                          hassignment[:resources] = assignment.resources.map(&:to_hash)
                          hassignment[:type_assignment_description] = assignment.type_assignment.description

                          hassignment[:fait] = assignment.fait_par?( eleve_id ) unless eleve_id.nil?
                          hassignment[:date_fait] = assignment.fait_le( eleve_id ) if hassignment[:fait]

                          hassignment
                      end }
                end
            end
                 .flatten
                 .compact
        end
    end
end
