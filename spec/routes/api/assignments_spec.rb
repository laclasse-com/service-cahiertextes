# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Assignments' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    ts = nil
    session = nil

    before( :all ) do
        ts = Timeslot.create( structure_id: MOCK_UAI,
                              group_id: 999_999,
                              subject_id: "SUBJECT_ID",
                              weekday: Time.now.wday,
                              start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                              end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )

        session = Session.create( timeslot_id: ts.id,
                                  author_id: LaClasse::Helpers::User.user['id'],
                                  date: DateTime.now,
                                  content: "test session",
                                  ctime: DateTime.now )

        ts.add_session( session )
    end

    after( :all ) do
        ts.assignments.each do |a|
            a.assignment_done_markers.each(&:destroy)
            a.destroy
        end
        ts.sessions.each(&:destroy)
        ts&.destroy
    end

    MOCK_DATE = DateTime.now
    MOCK_ASSIGNMENT_TYPE_ID = AssignmentType.first.id
    MOCK_CONTENT = "test assignment"

    aid = nil

    it 'creates an assignment' do
        post '/api/assignments/',
             timeslot_id: ts.id,
             session_id: session.id,
             assignment_type_id: MOCK_ASSIGNMENT_TYPE_ID,
             content: MOCK_CONTENT,
             date_due: MOCK_DATE.end_of_week,
             time_estimate: 5

        body = JSON.parse( last_response.body )
        aid = body['id']
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['assignment_type_id'] ).to eq MOCK_ASSIGNMENT_TYPE_ID
        expect( body['date_due'] ).to eq MOCK_DATE.end_of_week.strftime("%F")
        expect( body['content'] ).to eq MOCK_CONTENT
        expect( body['time_estimate'] ).to eq 5
    end

    it 'creates an assignment' do
        post '/api/assignments/',
             timeslot_id: ts.id,
             assignment_type_id: MOCK_ASSIGNMENT_TYPE_ID,
             content: MOCK_CONTENT,
             date_due: MOCK_DATE.end_of_week,
             time_estimate: 5

        body = JSON.parse( last_response.body )
        aid = body['id']
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['assignment_type_id'] ).to eq MOCK_ASSIGNMENT_TYPE_ID
        expect( body['date_due'] ).to eq MOCK_DATE.end_of_week.strftime("%F")
        expect( body['content'] ).to eq MOCK_CONTENT
        expect( body['time_estimate'] ).to eq 5
    end

    it 'modifies an assignment' do
        put "/api/assignments/#{aid}",
            assignment_type_id: MOCK_ASSIGNMENT_TYPE_ID + 1,
            content: "#{MOCK_CONTENT}#{MOCK_CONTENT}",
            date_due: MOCK_DATE.end_of_month,
            time_estimate: 15

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq aid
        expect( body['assignment_type_id'] ).to eq MOCK_ASSIGNMENT_TYPE_ID + 1
        expect( body['date_due'] ).to eq MOCK_DATE.end_of_month.strftime("%F")
        expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
        expect( body['time_estimate'] ).to eq 15
    end

    it 'gets an assignment by id' do
        get "/api/assignments/#{aid}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq aid
        expect( body['assignment_type_id'] ).to eq MOCK_ASSIGNMENT_TYPE_ID + 1
        expect( body['date_due'] ).to eq MOCK_DATE.end_of_month.strftime("%F")
        expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
        expect( body['time_estimate'] ).to eq 15
    end

    # it 'gets an assignment by timeslots_ids' do
    #     get "/api/assignments/",
    #         timeslots_ids: [ ts.id ]

    #     body = JSON.parse( last_response.body )
    #     expect( body['id'] ).to eq aid
    #     expect( body['assignment_type_id'] ).to eq MOCK_ASSIGNMENT_TYPE_ID + 1
    #     expect( body['date_due'] ).to eq MOCK_DATE.end_of_month.strftime("%F")
    #     expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
    #     expect( body['time_estimate'] ).to eq 15
    # end

    it 'marks an assignment as done by user' do
        put "/api/assignments/#{aid}",
            done: true

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq aid
        expect( body['rtime'] ).to_not be nil
    end

    it 'unmarks an assignment as done by user' do
        put "/api/assignments/#{aid}",
            done: false

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq aid
        expect( body['rtime'] ).to be nil
    end

    it 'deletes an assignment by id' do
        delete "/api/assignments/#{aid}"

        body = JSON.parse( last_response.body )

        expect( body['dtime'] ).to_not be nil
        expect( body['id'] ).to eq aid
        expect( body['timeslot_id'] ).to eq ts.id
    end

    it 'copies an assignment to a different timeslot/session' do
        ts2 = Timeslot.create( structure_id: MOCK_UAI,
                               group_id: 111_111,
                               subject_id: "SUBJECT_ID",
                               weekday: Time.now.wday + 1,
                               start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                               end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )

        copy_date = DateTime.now + 1.day

        session2 = Session.create( timeslot_id: ts2.id,
                                   author_id: LaClasse::Helpers::User.user['id'],
                                   date: DateTime.now,
                                   content: "test session",
                                   ctime: DateTime.now )

        ts2.add_session( session )

        post "/api/assignments/#{aid}/copy_to/timeslot/#{ts2.id}/date_due/#{copy_date}/session/#{session2.id}"

        expect( ts2.assignments.length ).to eq 1
        expect( ts2.assignments.first.id ).to_not eq aid
        expect( ts2.assignments.first.timeslot_id ).to eq ts2.id
        expect( ts2.assignments.first.session_id ).to eq session2.id
        expect( ts2.assignments.first.author_id ).to eq Assignment[aid].author_id
    end
end
