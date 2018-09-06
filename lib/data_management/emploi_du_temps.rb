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
                      devoirs: timeslot.devoirs
                                      .select { |devoir| devoir[:deleted] == false && devoir.date_due == day }
                                      .map do |devoir|
                          hdevoir = devoir.to_hash
                          hdevoir[:resources] = devoir.resources.map(&:to_hash)
                          hdevoir[:type_devoir_description] = devoir.type_devoir.description

                          hdevoir[:fait] = devoir.fait_par?( eleve_id ) unless eleve_id.nil?
                          hdevoir[:date_fait] = devoir.fait_le( eleve_id ) if hdevoir[:fait]

                          hdevoir
                      end }
                end
            end
                 .flatten
                 .compact
        end
    end
end
