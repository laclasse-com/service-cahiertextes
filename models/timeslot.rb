# frozen_string_literal: true

require_relative '../lib/utils'

class TimeslotResource < Sequel::Model( :timeslots_resources )
    unrestrict_primary_key

    many_to_one :timeslot
    many_to_one :resource
end

class Timeslot < Sequel::Model( :timeslots )
    many_to_many :resources, class: :Resource, join_table: :timeslots_resources
    one_to_many :sessions
    one_to_many :assignments
    many_to_one :import, class: :Import, key: :import_id

    def to_hash
        h = super
        h.each { |k, v| h[k] = v.iso8601 if v.is_a?( Time ) }

        h
    end

    def detailed( _date_start, _date_end, details )
        h = to_hash

        details.each { |detail| h[ detail.to_sym ] = send( detail ) if self.class.method_defined?( detail ) }

        h
    end

    def similar( groups_ids, date_start, date_end )
        date_start = Date.parse( date_start )
        date_end = Date.parse( date_end )
        query = Timeslot.where( subject_id: subject_id )
                        .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
                        .where( Sequel.lit( "`dtime` IS NULL OR DATE_FORMAT( dtime, '%Y-%m-%d') >= '#{end_time}'" ) )

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

    def update_resource( resource_id, active_weeks_resource )
        timeslot_resource = TimeslotResource[timeslot_id: id, resource_id: resource_id]
        if timeslot_resource.nil?
            resource = Resource[resource_id]
            return nil if resource.nil?

            add_resource( resource )

            timeslot_resource = TimeslotResource[timeslot_id: id, resource_id: resource_id]
        end

        timeslot_resource.update( active_weeks: active_weeks_resource ) unless active_weeks_resource.nil?
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

        update_resource( params['resource_id'], params['active_weeks_resource'] ) if params.key?( 'resource_id' )
    rescue StandardError => e
        puts "Can't do that with #{self}"
        puts e.message
        puts e.backtrace
    end

    def deep_destroy
        remove_all_sessions
        remove_all_assignments
        remove_all_resources

        destroy
    end
end
