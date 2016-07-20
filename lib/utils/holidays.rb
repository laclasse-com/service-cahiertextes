# encoding: utf-8
# -*- coding: utf-8 -*-

require 'open-uri'
require 'icalendar'

module CahierDeTextesApp
  module Utils
    module Holidays
      module_function

      def get( zone, year_rentree )
        raise( ArgumentError, 'Valid zones are ["A", "B", "C"]' ) unless %w(A B C).include?( zone )

        uri = "http://www.education.gouv.fr/download.php?file=http://cache.media.education.gouv.fr/ics/Calendrier_Scolaire_Zone_#{zone}.ics"

        ics = Icalendar::Calendar.parse( open( uri ) ).first
        description_rentrée_enseignants = ics.events.first.description
        this_year = false

        holidays_weeks = ics.events.map do |e|
          this_year = e.dtstart.to_date.year == year_rentree if e.description == description_rentrée_enseignants

          next unless this_year

          [ e.description.downcase.include?( 'rentrée' ) ? e.dtstart.to_date.prev_week.cweek : e.dtstart.to_date.next_week.cweek,
            e.dtend.nil? ? nil : e.dtend.to_date.prev_week.cweek ]
        end.flatten.compact

        # add summer holidays' weeks
        holidays_weeks.concat( ( holidays_weeks.last .. holidays_weeks.first ).to_a )

        holidays_weeks.sort.uniq
      end

      def year_rentree
        DateTime.now.month > 6 ? DateTime.now.year : DateTime.now.year - 1
      end
    end
  end
end
