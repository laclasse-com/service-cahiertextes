# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Timeslots' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    timeslot = nil

    before :each do
        timeslot = Timeslot.create( structure_id: MOCK_UAI,
                                    group_id: MOCK_GROUP_ID,
                                    subject_id: MOCK_SUBJECT_ID,
                                    weekday: MOCK_WEEKDAY,
                                    start_time: MOCK_START_TIME,
                                    end_time: MOCK_END_TIME )
    end

    after :each do
        AssignmentDoneMarker.where( assignment_id: Assignment.where( timeslot_id: Timeslot.where( structure_id: MOCK_UAI ).select( :id ) ).select(:id) ).destroy
        Assignment.where( timeslot_id: Timeslot.where( structure_id: MOCK_UAI ).select( :id ) ).destroy
        Session.where( timeslot_id: Timeslot.where( structure_id: MOCK_UAI ).select( :id ) ).destroy
        timeslot.destroy
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

    it 'FORBIDS creation when not ENS, ADM, DOC' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        post '/api/timeslots/', timeslots: [ { structure_id: MOCK_UAI,
                                               group_id: MOCK_GROUP_ID,
                                               subject_id: MOCK_SUBJECT_ID,
                                               weekday: MOCK_WEEKDAY,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME } ]

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'creates a Timeslot' do
        post '/api/timeslots/', timeslots: [ { structure_id: MOCK_UAI,
                                               group_id: MOCK_GROUP_ID,
                                               subject_id: MOCK_SUBJECT_ID,
                                               weekday: MOCK_WEEKDAY,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME } ]

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq 1
        expect( body.first.length ).to eq Timeslot.columns.count
        expect( body.first['structure_id'] ).to eq MOCK_UAI
        expect( body.first['group_id'] ).to eq MOCK_GROUP_ID
        expect( body.first['subject_id'] ).to eq MOCK_SUBJECT_ID
        expect( body.first['weekday'] ).to eq MOCK_WEEKDAY
        expect( body.first['start_time'] ).to eq MOCK_START_TIME
        expect( body.first['end_time'] ).to eq MOCK_END_TIME
        expect( body.first['import_id'] ).to be nil
    end

    it 'creates a Timeslot as part of importing' do
        import = Import.create( ctime: Time.now,
                                import_type_id: ImportType.first.id,
                                structure_id: MOCK_UAI,
                                author_id: u_id )
        post '/api/timeslots/', timeslots: [ { structure_id: MOCK_UAI,
                                               group_id: MOCK_GROUP_ID,
                                               subject_id: MOCK_SUBJECT_ID,
                                               weekday: MOCK_WEEKDAY,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME,
                                               import_id: import.id } ]

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq 1
        expect( body.first.length ).to eq Timeslot.columns.count
        expect( body.first['structure_id'] ).to eq MOCK_UAI
        expect( body.first['group_id'] ).to eq MOCK_GROUP_ID
        expect( body.first['subject_id'] ).to eq MOCK_SUBJECT_ID
        expect( body.first['weekday'] ).to eq MOCK_WEEKDAY
        expect( body.first['start_time'] ).to eq MOCK_START_TIME
        expect( body.first['end_time'] ).to eq MOCK_END_TIME
        expect( body.first['import_id'] ).to eq import.id

        Timeslot[body.first['id']]&.destroy
        import&.destroy
    end

    it 'FORBIDS getting a Timeslot from a structure the user does not belong to' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars
        $mock_user['profiles'].first['structure_id'] = 'abc'  # rubocop:disable Style/GlobalVars

        get "/api/timeslots/#{timeslot.id}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'FORBIDS getting a Timeslot from a group the user does not belong to' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars
        $mock_user['groups'].first['group_id'] = MOCK_GROUP_ID - 1  # rubocop:disable Style/GlobalVars

        get "/api/timeslots/#{timeslot.id}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'gets a Timeslot by id' do
        get "/api/timeslots/#{timeslot.id}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq timeslot.id
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
        cohort = Timeslot.where(structure_id: MOCK_UAI)
                         .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils::Calendar.schoolyear_start_date( 'A' )}'" ) )
                         .where( dtime: nil )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Timeslots by groups_ids' do
        get "/api/timeslots", groups_ids: [ MOCK_GROUP_ID ]

        body = JSON.parse( last_response.body )
        cohort = Timeslot.where(group_id: [ MOCK_GROUP_ID ])
                         .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils::Calendar.schoolyear_start_date( 'A' )}'" ) )
                         .where( dtime: nil )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Timeslots by subjects_ids' do
        get "/api/timeslots", subjects_ids: [ MOCK_SUBJECT_ID ]

        body = JSON.parse( last_response.body )
        cohort = Timeslot.where(subject_id: [ MOCK_SUBJECT_ID ])
                         .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils::Calendar.schoolyear_start_date( 'A' )}'" ) )
                         .where( dtime: nil )
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
                         .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils::Calendar.schoolyear_start_date( 'A' )}'" ) )
                         .where( dtime: nil )
        expect( body.length ).to eq cohort.count
    end

    # TODO: include_deleted
    # TODO: no_year_restriction
    # TODO: date>
    # TODO: date<
    # TODO: import_id

    it 'FORBIDS update when not ENS, ADM, DOC' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        put "/api/timeslots/#{timeslot.id}",
            group_id: MOCK_GROUP_ID + 1,
            subject_id: "#{MOCK_SUBJECT_ID}2",
            weekday: MOCK_WEEKDAY + 1,
            start_time: MOCK_START_TIME,
            end_time: MOCK_END_TIME

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'modifies a Timeslot' do
        put "/api/timeslots/#{timeslot.id}",
            group_id: MOCK_GROUP_ID + 1,
            subject_id: "#{MOCK_SUBJECT_ID}2",
            weekday: MOCK_WEEKDAY + 1,
            start_time: MOCK_START_TIME,
            end_time: MOCK_END_TIME

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq timeslot.id
        expect( body['structure_id'] ).to eq MOCK_UAI
        expect( body['group_id'] ).to eq MOCK_GROUP_ID + 1
        expect( body['subject_id'] ).to eq "#{MOCK_SUBJECT_ID}2"
        expect( body['weekday'] ).to eq MOCK_WEEKDAY + 1
        expect( body['start_time'] ).to eq MOCK_START_TIME
        expect( body['end_time'] ).to eq MOCK_END_TIME
    end

    it 'FORBIDS deletion when not ENS, ADM, DOC' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        delete "/api/timeslots/#{timeslot.id}", dtime: Time.now

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'deletes a Timeslot by id' do
        delete "/api/timeslots/#{timeslot.id}", dtime: Time.now

        expect( Timeslot[id: timeslot.id].dtime ).to_not be nil
    end
end
