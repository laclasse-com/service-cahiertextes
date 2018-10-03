# frozen_string_literal: true

require 'open-uri'
require 'icalendar'

module Utils
    module_function

    module Holidays
        module_function

        def get( zone, start_year = year_rentree )
            raise( ArgumentError, 'Valid zones are ["A", "B", "C"]' ) unless %w[A B C].include?( zone )

            uri = URI.parse( "http://www.education.gouv.fr/download.php?file=http://cache.media.education.gouv.fr/ics/Calendrier_Scolaire_Zone_#{zone}.ics" )

            ics = Icalendar::Calendar.parse( uri.open ).first
            description_rentrée_enseignants = ics.events.first.description
            this_year = false

            holidays_weeks = ics.events.map do |e|
                this_year = e.dtstart.to_date.year == start_year if e.description == description_rentrée_enseignants

                next unless this_year

                start_week_offset = ( e.description.downcase.include?( 'rentrée' ) ? ( e.dtstart.to_date.cwday == 1 ? -1 : 0 ) : 1 ) # rubocop:disable Style/NestedTernaryOperator
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

        def year_rentree
            DateTime.now.month > 6 ? DateTime.now.year : DateTime.now.year - 1
        end
    end

    def date_rentree
        Date.parse( "#{Date.today.month > 8 ? Date.today.year : Date.today.year - 1}-08-15" )
    end

    def deep_dup( thing )
        Marshal.load( Marshal.dump( thing ) )
    end
end
