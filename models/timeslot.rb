# frozen_string_literal: true

require_relative '../lib/utils'

class TimeslotLocation < Sequel::Model( :timeslots_locations )
    unrestrict_primary_key

    many_to_one :timeslot
    many_to_one :location
end

class Timeslot < Sequel::Model( :timeslots )
    many_to_many :locations, class: :Location, join_table: :timeslots_locations
    one_to_many :sessions
    one_to_many :assignments
    many_to_one :import, class: :Import, key: :import_id

    def toggle_deleted( dtime )
        update( deleted: !deleted, dtime: deleted ? nil : dtime )

        save
    end

    def to_hash
        h = super
        h.each { |k, v| h[k] = v.iso8601 if v.is_a?( Time ) }

        h
    end

    def detailed( _date_start, _date_end, details )
        h = to_hash

        details.each { |detail| h[ detail.to_sym ] = send( detail ) if self.class.method_deended?( detail ) }

        h
    end

    def duplicates
        Timeslot
            .select_append( :timeslots__id___id )
            .where( Sequel.~( timeslots__id: id ) )
            .where( subject_id: subject_id )
            .where( weekday: weekday )
            .where( group_id: group_id )
            .where( active_weeks: active_weeks )
            .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
            .where( deleted: false )
    end

    # attach session and assignments to this timeslot and destroy other_timeslot
    def merge( timeslot_id )
        other_timeslot = Timeslot[timeslot_id]
        return false if other_timeslot.nil?

        other_timeslot.sessions.each do |session|
            session.update( timeslot_id: id )
            session.save
        end
        other_timeslot.assignments.each do |assignment|
            assignment.update( timeslot_id: id )
            assignment.save
        end
    end

    def merge_twins
        return [] if deleted

        duplicates.select(:timeslot__id)
                  .naked
                  .all
                  .map do |twin_id|
            twin = Timeslot[ twin_id[:id] ]
            next if twin.deleted

            merge( twin.id )

            twin.id
        end
    end

    def merge_and_destroy_twins( truly_destroy = false )
        merge_twins.map do |twin_id|
            if truly_destroy
                Timeslot[twin_id].deep_destroy
            else
                Timeslot[twin_id].toggle_deleted( Time.now )
            end

            twin_id
        end
    end

    def similar( groups_ids, date_start, date_end )
        date_start = Date.parse( date_start )
        date_end = Date.parse( date_end )
        query = Timeslot.where( subject_id: subject_id )
                        .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
                        .where( Sequel.lit( "`deleted` IS FALSE OR (`deleted` IS TRUE AND DATE_FORMAT( dtime, '%Y-%m-%d') >= '#{end_time}')" ) )

        query = query.where( group_id: groups_ids ) unless groups_ids.nil?

        query.all
             .map do |c|
            ( date_start .. date_end )
                .select { |day| day.wday == c.weekday }
                .map do |jour|
                next unless c.active_weeks[jour.cweek] == 1

                { id: c.id,
                  timeslot_id: c.id,
                  start_time: Time.new( jour.year, jour.month, jour.mday, c.start_time.hour, c.start_time.min ).iso8601,
                  end_time: Time.new( jour.year, jour.month, jour.mday, c.end_time.hour, c.end_time.min ).iso8601,
                  has_session: c.session.count { |session| session.date_session == jour }.positive?,
                  weekday: c.weekday,
                  subject_id: c.subject_id,
                  group_id: c.group_id,
                  active_weeks: c.active_weeks }
            end
        end
             .flatten
             .compact
    end

    def update_location( location_id, active_weeks_location )
        timeslot_location = TimeslotLocation[timeslot_id: id, location_id: location_id]
        if timeslot_location.nil?
            location = Location[location_id]
            return nil if location.nil?

            add_location( location )

            timeslot_location = TimeslotLocation[timeslot_id: id, location_id: location_id]
        end

        timeslot_location.update( active_weeks: active_weeks_location ) unless active_weeks_location.nil?
    end

    def modify( params )
        update( start_time: params['start_time'] ) if params.key?( 'start_time' )
        update( end_time: params['end_time'] ) if params.key?( 'end_time' )

        update( subject_id: params['subject_id'] ) if params.key?( 'subject_id' )
        update( import_id: params['import_id'] ) if params.key?( 'import_id' )
        update( weekday: params['weekday'] ) if params.key?( 'weekday' )
        update( group_id: params['group_id'] ) if params.key?( 'group_id' )
        update( active_weeks: params['active_weeks_group'] ) if params.key?( 'active_weeks_group' )

        save

        update_location( params['location_id'], params['active_weeks_location'] ) if params.key?( 'location_id' )
    rescue StandardError => e
        puts "Can't do that with #{self}"
        puts e.message
        puts e.backtrace
    end

    def deep_destroy
        remove_all_sessions
        remove_all_assignments
        remove_all_locations

        destroy
    end
end
