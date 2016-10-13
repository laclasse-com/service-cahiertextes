# encoding: utf-8
# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Utils
    module Semainier
      module_function

      def jsonify_semainier( semainier )
        # FIXME: hardcoded zone A
        vacances = CahierDeTextesApp::Utils::Holidays.get( 'A', CahierDeTextesApp::Utils::Holidays.year_rentree )
        semainier = semainier.to_s( 2 )
                             .ljust( 52, '0' )
        semainier = "#{semainier}#{semainier[semainier.length - 1]}"
        semainier[0] = ''
        semainier.split( '' )
                 .map
                 .with_index { |w, i| { week: i + 1, presence: w == '1', holidays: vacances.include?( i + 1 ) } }
                 .group_by { |w| Date::MONTHNAMES[ Date.commercial( w[:week] < 30 ? 2016 : 2015, w[:week] ).month ] }
      end

      def pretty_print_semainier( semainier )
        jsonified_semainier = jsonify_semainier( semainier )
        semaine_to_s = lambda do |semaine|
          return '  ' if semaine.nil?
          v1 = semaine[:holidays] ? '[' : ' '
          v2 = semaine[:holidays] ? ']' : ' '
          "#{v1}#{semaine[:presence] ? '1' : '0'}#{v2}"
        end

        month_name_length = jsonified_semainier.keys.map(&:length).max
        semainier = jsonified_semainier.keys.map { |month_name| "#{'|' + ' ' * (month_name_length - month_name.length)}#{month_name}" }.join
        semainier += "\n"
        semainier += jsonified_semainier.map { |month| '|' + "#{semaine_to_s.call( month[1][0] )}#{semaine_to_s.call( month[1][1] )}".ljust( month_name_length, ' ') }.join
        semainier += "\n"
        semainier += jsonified_semainier.map { |month| '|' + "#{semaine_to_s.call( month[1][2] )}#{semaine_to_s.call( month[1][3] )}".ljust( month_name_length, ' ') }.join
        semainier += "\n"
        semainier += jsonified_semainier.map { |month| '|' + "#{semaine_to_s.call( month[1][4] )}   ".ljust( month_name_length, ' ') }.join
        semainier += "\n"

        semainier
      end

      def all_school_year_semainier( zone, year_rentree )
        holidays_weeks = CahierDeTextesApp::Utils::Holidays.get( zone, year_rentree )
        (1..53).to_a.map { |i| holidays_weeks.include?( i ) ? '0' : '1' }.join.reverse.to_i( 2 )
      end

      def activate_semaine( semainier, n )
        semainier | 2**n
      end
    end
  end
end
