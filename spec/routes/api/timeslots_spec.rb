# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Timeslots' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    MOCK_WEEKDAY = Time.now.wday
    MOCK_START_TIME = Time.now.strftime( "2000-01-01T%H:00:00+01:00" )
    MOCK_END_TIME = Time.now.strftime( "2000-01-01T%H:30:00+01:00" )
    MOCK_GROUP_ID = 999_999
    MOCK_SUBJECT_ID = "SUBJECT_ID"

    tid = -1

    before :all do
        AssignmentDoneMarker.where( assignment_id: Assignment.where( timeslot_id: Timeslot.where( structure_id: MOCK_UAI ).select( :id ) ).select(:id) ).destroy
        Assignment.where( timeslot_id: Timeslot.where( structure_id: MOCK_UAI ).select( :id ) ).destroy
        Session.where( timeslot_id: Timeslot.where( structure_id: MOCK_UAI ).select( :id ) ).destroy
        Timeslot.where( structure_id: MOCK_UAI ).destroy
    end

    it 'creates multiple Timeslots' do
        post '/api/timeslots/', timeslots: [ { structure_id: MOCK_UAI,
                                               group_id: MOCK_GROUP_ID,
                                               subject_id: MOCK_SUBJECT_ID,
                                               weekday: MOCK_WEEKDAY,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME },
                                             { structure_id: MOCK_UAI,
                                               group_id: MOCK_GROUP_ID + 1,
                                               subject_id: MOCK_SUBJECT_ID,
                                               weekday: MOCK_WEEKDAY,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME } ]

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 2

        body.each do |ts|
            expect( ts['structure_id'] ).to eq MOCK_UAI
            expect( [ MOCK_GROUP_ID, MOCK_GROUP_ID + 1 ] ).to include( ts['group_id'] )
            expect( ts['subject_id'] ).to eq MOCK_SUBJECT_ID
            expect( ts['weekday'] ).to eq MOCK_WEEKDAY
            expect( ts['start_time'] ).to eq MOCK_START_TIME
            expect( ts['end_time'] ).to eq MOCK_END_TIME
        end

        Timeslot.where(id: body.map { |t| t['id'] }).destroy
    end

    it 'creates a Timeslot' do
        post '/api/timeslots/',
             structure_id: MOCK_UAI,
             group_id: MOCK_GROUP_ID,
             subject_id: MOCK_SUBJECT_ID,
             weekday: MOCK_WEEKDAY,
             start_time: MOCK_START_TIME,
             end_time: MOCK_END_TIME

        body = JSON.parse( last_response.body )
        tid = body['id']

        expect( body.length ).to eq Timeslot.columns.count
        expect( body['structure_id'] ).to eq MOCK_UAI
        expect( body['group_id'] ).to eq MOCK_GROUP_ID
        expect( body['subject_id'] ).to eq MOCK_SUBJECT_ID
        expect( body['weekday'] ).to eq MOCK_WEEKDAY
        expect( body['start_time'] ).to eq MOCK_START_TIME
        expect( body['end_time'] ).to eq MOCK_END_TIME
    end

    it 'gets a Timeslot by id' do
        get "/api/timeslots/#{tid}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq tid
        expect( body['structure_id'] ).to eq MOCK_UAI
        expect( body['group_id'] ).to eq MOCK_GROUP_ID
        expect( body['subject_id'] ).to eq MOCK_SUBJECT_ID
        expect( body['weekday'] ).to eq MOCK_WEEKDAY
        expect( body['start_time'] ).to eq MOCK_START_TIME
        expect( body['end_time'] ).to eq MOCK_END_TIME
    end

    it 'gets Timeslots by structure_id' do
        get "/api/timeslots", structure_id: MOCK_UAI

        body = JSON.parse( last_response.body )
        cohort = Timeslot.where(structure_id: MOCK_UAI).where( Sequel.~( :deleted ) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Timeslots by groups_ids' do
        get "/api/timeslots", groups_ids: [ MOCK_GROUP_ID ]

        body = JSON.parse( last_response.body )
        cohort = Timeslot.where(group_id: [ MOCK_GROUP_ID ]).where( Sequel.~( :deleted ) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Timeslots by subjects_ids' do
        get "/api/timeslots", subjects_ids: [ MOCK_SUBJECT_ID ]

        body = JSON.parse( last_response.body )
        cohort = Timeslot.where(subject_id: [ MOCK_SUBJECT_ID ]).where( Sequel.~( :deleted ) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Timeslots by structure_id and groups_ids and subjects_ids' do
        get "/api/timeslots",
            structure_id: MOCK_UAI,
            groups_ids: [ MOCK_GROUP_ID ],
            subjects_ids: [ MOCK_SUBJECT_ID ]

        body = JSON.parse( last_response.body )
        cohort = Timeslot.where(structure_id: MOCK_UAI)
                         .where(group_id: [ MOCK_GROUP_ID ])
                         .where(subject_id: [ MOCK_SUBJECT_ID ])
                         .where( Sequel.~( :deleted ) )
        expect( body.length ).to eq cohort.count
    end

    # TODO: include_deleted
    # TODO: no_year_restriction
    # TODO: date>
    # TODO: date<
    # TODO: import_id

    it 'modifies a Timeslot' do
        put "/api/timeslots/#{tid}",
            group_id: MOCK_GROUP_ID + 1,
            subject_id: "#{MOCK_SUBJECT_ID}2",
            weekday: MOCK_WEEKDAY + 1,
            start_time: MOCK_START_TIME,
            end_time: MOCK_END_TIME

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq tid
        expect( body['structure_id'] ).to eq MOCK_UAI
        expect( body['group_id'] ).to eq MOCK_GROUP_ID + 1
        expect( body['subject_id'] ).to eq "#{MOCK_SUBJECT_ID}2"
        expect( body['weekday'] ).to eq MOCK_WEEKDAY + 1
        expect( body['start_time'] ).to eq MOCK_START_TIME
        expect( body['end_time'] ).to eq MOCK_END_TIME
    end

    it 'deletes a Timeslot by id' do
        delete "/api/timeslots/#{tid}", dtime: Time.now

        expect( Timeslot[id: tid].deleted ).to be true
    end
end
