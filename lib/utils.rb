# frozen_string_literal: true

require 'open-uri'
require 'icalendar'

module Utils
    module_function

    module Calendar
        module_function

        @@official_calendar = nil # rubocop:disable Style/ClassVars

        def holidays( zone, schoolyear_start_year = nil )
            fetch_official_calendar( zone ) if @@official_calendar.nil?
            schoolyear_start_year = schoolyear_start_date( zone ).year if schoolyear_start_year.nil?

            description_rentrée_enseignants = @@official_calendar.events.first.description
            this_year = false

            holidays_weeks = @@official_calendar.events.map do |e|
                this_year = e.dtstart.to_date.year == schoolyear_start_year if e.description == description_rentrée_enseignants

                next unless this_year

                start_week_offset = ( e.description.downcase.force_encoding('UTF-8').include?( 'rentrée' ) ? ( e.dtstart.to_date.cwday == 1 ? -1 : 0 ) : 1 ) # rubocop:disable Style/NestedTernaryOperator
                [e.dtstart.to_date.cweek + start_week_offset,
                 e.dtend.nil? ? nil : e.dtend.to_date.cweek - 1]
            end.flatten.compact

            # add summer holidays' weeks
            holidays_weeks.concat( ( holidays_weeks.last .. holidays_weeks.first ).to_a )

            holidays_weeks.sort.uniq
        rescue StandardError => e
            puts e.message
            puts e.backtrace

            []
        end

        def schoolyear_start_date( zone )
            fetch_official_calendar( zone ) if @@official_calendar.nil?

            @@official_calendar.events.find { |e| e.description.force_encoding('UTF-8').match?( "^Rentrée.*" ) }.dtstart
        end

        def fetch_official_calendar( zone )
            raise( ArgumentError, 'Valid zones are ["A", "B", "C"]' ) unless %w[A B C].include?( zone )

            uri = URI.parse( "http://cache.media.education.gouv.fr/ics/Calendrier_Scolaire_Zone_#{zone}.ics" )

            @@official_calendar = Icalendar::Calendar.parse( uri.open ).first # rubocop:disable Style/ClassVars
        end
    end

    def deep_dup( thing )
        Marshal.load( Marshal.dump( thing ) )
    end
end
