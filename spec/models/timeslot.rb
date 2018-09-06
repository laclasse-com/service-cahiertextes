require 'spec_helper'

describe Timeslot do
    before :each do
        @structure = Structure.create( UAI: 'test012345Z' )
        @weekday = rand( 1..5 )
        @timeslot = Timeslot.create( ctime: Time.now,
                                     start_time: Time.parse( '14:00' ),
                                     end_time: Time.parse( '15:00' ),
                                     weekday: @weekday,
                                     subject_id: '',
                                     group_id: 0,
                                     structure_id: @structure.id )
        @location = Location.create( structure_id: @structure.id,
                                     label: 'test' )
    end
    after :each do
        @timeslot.remove_all_locations
        @timeslot.destroy
        @location.destroy
        @structure.destroy
    end

    it 'creates a placeholder creneau' do
        expect( @timeslot ).to_not be_nil
        expect( @timeslot.group_id ).to eq 0
        expect( @timeslot.locations ).to be_empty
        expect( @timeslot.cours ).to be_empty
        expect( @timeslot.devoirs ).to be_empty
        expect( @timeslot.start_time.iso8601.split('+').first.split('T').last ).to eq '14:00:00'
        expect( @timeslot.end_time.iso8601.split('+').first.split('T').last ).to eq '15:00:00'
        expect( @timeslot.weekday ).to eq @weekday
        expect( @timeslot.subject_id ).to be_empty
        expect( @timeslot.structure_id ).to eq @structure.id
    end

    it 'def toggle_deleted( dtime )' do
        dtime = Time.now

        @timeslot.toggle_deleted( dtime )

        expect( @timeslot.deleted ).to be true
        expect( @timeslot.dtime ).to eq dtime

        @timeslot.toggle_deleted( dtime )

        expect( @timeslot.deleted ).to be false
        expect( @timeslot.dtime ).to be nil
    end

    it 'def similaires( start_time, end_time, user )' do
        expect( 1 ).to eq 1
        STDERR.puts 'FIXME'
    end

    it 'def modifie( params ) # hours as string' do
        @timeslot.modifie( 'start_time' => '12:34',
                           'end_time' => '23:45' )
        expect( @timeslot.start_time.iso8601.split('+').first.split('T').last ).to eq '12:34:00'
        expect( @timeslot.end_time.iso8601.split('+').first.split('T').last ).to eq '23:45:00'
    end

    it 'def modifie( params ) # hours as Time' do
        @timeslot.modifie( 'start_time' => Time.parse( '10:02' ),
                           'end_time' => Time.parse( '21:09' ) )
        expect( @timeslot.start_time.iso8601.split('+').first.split('T').last ).to eq '10:02:00'
        expect( @timeslot.end_time.iso8601.split('+').first.split('T').last ).to eq '21:09:00'
    end

    it 'def modifie( params ) # change subject' do
        @timeslot.modifie( 'subject_id' => 'dummy_subject_id' )
        expect( @timeslot.subject_id ).to eq 'dummy_subject_id'
    end

    it 'def modifie( params ) # change day' do
        @timeslot.modifie( 'weekday' => @weekday + 1 )
        expect( @timeslot.weekday ).to eq @weekday + 1
    end

    it 'def modifie( params ) # add group' do
        @timeslot.modifie( 'group_id' => 999_999 )
        expect( @timeslot.group_id ).to eq 999_999
        expect( @timeslot.active_weeks ).to eq 2**52 - 1
    end

    it 'def modifie( params ) # change group' do
        @timeslot.modifie( 'group_id' => 999_999 )
        expect( @timeslot.group_id ).to eq 999_999

        @timeslot.modifie( 'group_id' => 999_999,
                           'active_weeks_group' => 123)
        expect( @timeslot.group_id ).to eq 999_999
        expect( @timeslot.active_weeks ).to eq 123
    end

    it 'def modifie( params ) # add location' do
        @timeslot.modifie( 'location_id' => @location.id )
        expect( @timeslot.locations.count ).to eq 1
        expect( TimeslotLocation[ timeslot_id: @timeslot.id,
                                  location_id: @location.id ] ).to_not be nil
        expect( TimeslotLocation[ timeslot_id: @timeslot.id,
                                  location_id: @location.id ].active_weeks ).to eq 2**52 - 1
    end

    it 'def modifie( params ) # change location' do
        @timeslot.modifie( 'location_id' => @location.id )
        expect( @timeslot.locations.count ).to eq 1
        expect( TimeslotLocation[ timeslot_id: @timeslot.id,
                                  location_id: @location.id ] ).to_not be nil
        expect( TimeslotLocation[ timeslot_id: @timeslot.id,
                                  location_id: @location.id ].active_weeks ).to eq 2**52 - 1
        @timeslot.modifie( 'location_id' => @location.id,
                           'active_weeks_location' => 123)
        expect( @timeslot.locations.count ).to eq 1
        expect( TimeslotLocation[ timeslot_id: @timeslot.id,
                                  location_id: @location.id ] ).to_not be nil
        expect( TimeslotLocation[ timeslot_id: @timeslot.id,
                                  location_id: @location.id ].active_weeks ).to eq 123
    end
end
