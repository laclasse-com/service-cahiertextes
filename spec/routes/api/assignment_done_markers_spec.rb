# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::AssignmentDoneMarkers' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'creates a assignment_done_marker' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        ts = Timeslot.create( structure_id: MOCK_UAI,
                              group_id: 999_999,
                              subject_id: "SUBJECT_ID",
                              weekday: Time.now.wday,
                              start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                              end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        assignment = Content.create( author_id: u_id,
                                     timeslot_id: ts.id,
                                     date: MOCK_DATE,
                                     content: MOCK_CONTENT,
                                     type: "assignment",
                                     ctime: DateTime.now )

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        post '/api/assignment_done_markers/', assignment_done_markers: [ { author_id: u_id,
                                                                           content_id: assignment.id } ]

        body = JSON.parse( last_response.body )

        expect( body.first['rtime'] ).to_not be nil

        body.each do |t|
            AssignmentDoneMarker[id: t['id']]&.destroy
        end
        assignment.destroy
        ts.destroy
    end

    it 'CANNOT creates a duplicated assignment_done_marker' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        ts = Timeslot.create( structure_id: MOCK_UAI,
                              group_id: 999_999,
                              subject_id: "SUBJECT_ID",
                              weekday: Time.now.wday,
                              start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                              end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        assignment = Content.create( author_id: u_id,
                                     timeslot_id: ts.id,
                                     date: MOCK_DATE,
                                     content: MOCK_CONTENT,
                                     type: "assignment",
                                     ctime: DateTime.now )

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        post '/api/assignment_done_markers/', assignment_done_markers: [ { author_id: u_id,
                                                                           content_id: assignment.id } ]

        body = JSON.parse( last_response.body )

        post '/api/assignment_done_markers/', assignment_done_markers: [ { author_id: u_id,
                                                                           content_id: assignment.id } ]

        expect( last_response.status ).to eq 403

        body.each do |t|
            AssignmentDoneMarker[id: t['id']]&.destroy
        end
        assignment.destroy
        ts.destroy
    end

    it 'gets an assignment_done_marker by id' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        ts = Timeslot.create( structure_id: MOCK_UAI,
                              group_id: 999_999,
                              subject_id: "SUBJECT_ID",
                              weekday: Time.now.wday,
                              start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                              end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        assignment = Content.create( author_id: u_id,
                                     timeslot_id: ts.id,
                                     date: MOCK_DATE,
                                     content: MOCK_CONTENT,
                                     type: "assignment",
                                     ctime: DateTime.now )

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        post '/api/assignment_done_markers/', assignment_done_markers: [ { author_id: u_id,
                                                                           content_id: assignment.id } ]

        adm = JSON.parse( last_response.body )

        get "/api/assignment_done_markers/#{adm.first['id']}"

        body = JSON.parse( last_response.body )
        expect( body['author_id'].to_i ).to eq u_id
        expect( body['content_id'] ).to eq assignment.id
        expect( body['rtime'] ).to_not be nil

        AssignmentDoneMarker[id: body['id']]&.destroy
        assignment.destroy
        ts.destroy
    end

    it 'gets assignment_done_markers by author_id' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        ts = Timeslot.create( structure_id: MOCK_UAI,
                              group_id: 999_999,
                              subject_id: "SUBJECT_ID",
                              weekday: Time.now.wday,
                              start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                              end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        assignment = Content.create( author_id: u_id,
                                     timeslot_id: ts.id,
                                     date: MOCK_DATE,
                                     content: MOCK_CONTENT,
                                     type: "assignment",
                                     ctime: DateTime.now )

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        post '/api/assignment_done_markers/', assignment_done_markers: [ { author_id: u_id,
                                                                           content_id: assignment.id } ]

        get "/api/assignment_done_markers/", author_id: u_id

        body = JSON.parse( last_response.body )
        expect( body.first['author_id'].to_i ).to eq u_id
        expect( body.first['content_id'] ).to eq assignment.id
        expect( body.first['rtime'] ).to_not be nil

        AssignmentDoneMarker[id: body.first['id']]&.destroy
        assignment.destroy
        ts.destroy
    end

    it 'deletes a assignment_done_marker' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars
        ts = Timeslot.create( structure_id: MOCK_UAI,
                              group_id: 999_999,
                              subject_id: "SUBJECT_ID",
                              weekday: Time.now.wday,
                              start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                              end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        assignment = Content.create( author_id: u_id,
                                     timeslot_id: ts.id,
                                     date: MOCK_DATE,
                                     content: MOCK_CONTENT,
                                     type: "assignment",
                                     ctime: DateTime.now )

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        post '/api/assignment_done_markers/', assignment_done_markers: [ { author_id: u_id,
                                                                           content_id: assignment.id } ]

        adm = JSON.parse( last_response.body )

        delete "/api/assignment_done_markers/#{adm.first['id']}"

        expect( last_response.body ).to be_empty
        expect( AssignmentDoneMarker[id: adm.first['id']] ).to be_nil

        assignment.destroy
        ts.destroy
    end
end
