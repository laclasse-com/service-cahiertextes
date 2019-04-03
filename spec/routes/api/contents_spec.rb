# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Contents' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    ts = nil

    before( :each ) do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        ts = Timeslot.create( structure_id: MOCK_UAI,
                              group_id: 999_999,
                              subject_id: "SUBJECT_ID",
                              weekday: Time.now.wday,
                              start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                              end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
    end

    after( :each ) do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        ts.contents.each(&:remove_all_trails)
        ts.contents.each(&:destroy)
        ts&.destroy
    end

    it 'creates a Note' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "note" } ]

        body = JSON.parse( last_response.body )
        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['type'] ).to eq "note"

        Content[id: body.first['id']]&.destroy
    end

    it 'creates a Session' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]

        body = JSON.parse( last_response.body )
        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['type'] ).to eq "session"

        Content[id: body.first['id']]&.destroy
    end

    it 'creates a Session with attachments' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session",
                                             attachments: [ { type: "DOC", name: "tralala", external_id: "tralala" },
                                                            { type: "URL", name: "trilili", external_id: "trilili" }] } ]

        body = JSON.parse( last_response.body )
        created_content = Content[id: body.first['id']]

        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['type'] ).to eq "session"
        expect( created_content.attachments.length ).to eq 2
        expect( created_content.attachments.first.type ).to eq "DOC"
        expect( created_content.attachments.first.name ).to eq "tralala"
        expect( created_content.attachments.first.external_id ).to eq "tralala"
        expect( created_content.attachments.last.type ).to eq "URL"
        expect( created_content.attachments.last.name ).to eq "trilili"
        expect( created_content.attachments.last.external_id ).to eq "trilili"

        created_content&.remove_all_attachments
        created_content&.destroy
    end

    it 'creates an Assignment' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "assignment", parent_content_id: session.id, load: 2, assignment_type: "Exposé" } ]

        body = JSON.parse( last_response.body )
        created_content = Content[id: body.first['id']]

        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['type'] ).to eq "assignment"

        expect( session.children.length ).to eq 1
        expect( session.children.first.id ).to eq created_content.id
        expect( created_content.parent.id ).to eq session.id

        created_content&.destroy
        session&.destroy
    end

    it 'creates an Assignment with users' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "assignment", parent_content_id: session.id, load: 2, assignment_type: "Exposé", users_ids: [ MOCK_USER_ELV['id'] ] } ]

        body = JSON.parse( last_response.body )
        created_content = Content[id: body.first['id']]

        expect( created_content.users.length ).to eq 1
        expect( created_content.users.first.uid ).to eq MOCK_USER_ELV['id']

        created_content&.remove_all_users
        created_content&.destroy
        session&.destroy
    end

    it 'gets a Content by id' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "assignment", parent_content_id: session.id, load: 2, assignment_type: "Exposé" } ]
        assignment = Content[id: JSON.parse( last_response.body ).first['id'] ]

        get "/api/contents/#{assignment.id}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq assignment.id
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body['content'] ).to eq MOCK_CONTENT
        expect( body['dtime'] ).to be nil
        expect( body['author_id'] ).to eq u_id
        expect( body['type'] ).to eq "assignment"

        assignment&.destroy
        session&.destroy
    end

    it 'gets Notes by timeslot_id' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        ts2 = Timeslot.create( structure_id: MOCK_UAI,
                               group_id: 999_999,
                               subject_id: "SUBJECT_ID",
                               weekday: Time.now.wday,
                               start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                               end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts2.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "assignment", parent_content_id: session.id, load: 2, assignment_type: "Exposé" } ]
        assignment = Content[id: JSON.parse( last_response.body ).first['id'] ]

        get "/api/contents", timeslots_ids: [ ts.id ]

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq 1

        expect( body.first['id'] ).to eq session.id
        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['dtime'] ).to be nil
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['type'] ).to eq "session"

        assignment&.destroy
        session&.destroy
        ts2&.destroy
    end

    it 'gets Notes by trail_id' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        trail = Trail.create( label: "prout" )

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session", trails_ids: [trail.id] } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        get "/api/contents", trails_ids: [ trail.id ]

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq 1

        expect( body.first['id'] ).to eq session.id
        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['dtime'] ).to be nil
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['type'] ).to eq "session"

        session&.remove_all_trails
        session&.destroy
        trail&.destroy
    end

    it 'gets Notes by parent_content_id' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "assignment", parent_content_id: session.id, load: 2, assignment_type: "Exposé" } ]
        assignment = Content[id: JSON.parse( last_response.body ).first['id'] ]

        get "/api/contents", parent_contents_ids: [ session.id ]

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq 1

        expect( body.first['id'] ).to eq assignment.id
        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['dtime'] ).to be nil
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['type'] ).to eq "assignment"

        assignment&.destroy
        session&.destroy
    end

    it 'gets Notes by assignment_type' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "assignment", parent_content_id: session.id, load: 2, assignment_type: "Exposé" } ]
        assignment = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "assignment", parent_content_id: session.id, load: 2, assignment_type: "DM" } ]
        assignment2 = Content[id: JSON.parse( last_response.body ).first['id'] ]

        get "/api/contents", parent_contents_ids: [ session.id ], assignment_types: %w[Exposé]

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 1

        expect( body.first['id'] ).to eq assignment.id
        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['dtime'] ).to be nil
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['assignment_type'] ).to eq "Exposé"

        get "/api/contents", parent_contents_ids: [ session.id ], assignment_types: %w[DM]

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 1

        expect( body.first['id'] ).to eq assignment2.id
        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['dtime'] ).to be nil
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['assignment_type'] ).to eq "DM"

        get "/api/contents", parent_contents_ids: [ session.id ], assignment_types: %w[DM Exposé]

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 2

        get "/api/contents", parent_contents_ids: [ session.id ], assignment_types: %w[DS Travail]

        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 0

        assignment&.destroy
        assignment2&.destroy
        session&.destroy
    end

    it 'gets Notes by date' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE.end_of_week, content: MOCK_CONTENT, type: "session" } ]
        session2 = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE.end_of_month, content: MOCK_CONTENT, type: "session" } ]
        session3 = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE.end_of_year, content: MOCK_CONTENT, type: "session" } ]
        session4 = Content[id: JSON.parse( last_response.body ).first['id'] ]

        get "/api/contents", timeslots_ids: [ ts.id ], date: MOCK_DATE
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 1
        expect( body.first['id'] ).to eq session.id

        get "/api/contents", timeslots_ids: [ ts.id ], date: MOCK_DATE.end_of_week
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq MOCK_DATE.end_of_week == MOCK_DATE.end_of_month ? 2 : 1
        expect( body.first['id'] ).to eq session2.id

        get "/api/contents", timeslots_ids: [ ts.id ], date: MOCK_DATE.end_of_month
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq MOCK_DATE.end_of_week == MOCK_DATE.end_of_month ? 2 : 1
        expect( body.first['id'] ).to eq MOCK_DATE.end_of_week == MOCK_DATE.end_of_month ? session2.id : session3.id

        get "/api/contents", timeslots_ids: [ ts.id ], date: MOCK_DATE.end_of_year
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 1
        expect( body.first['id'] ).to eq session4.id

        get "/api/contents", timeslots_ids: [ ts.id ], "date<": MOCK_DATE.end_of_week
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq MOCK_DATE.end_of_week == MOCK_DATE.end_of_month ? 3 : 2
        expect( body.first['id'] ).to eq session.id
        expect( body.last['id'] ).to eq MOCK_DATE.end_of_week == MOCK_DATE.end_of_month ? session3.id : session2.id

        get "/api/contents", timeslots_ids: [ ts.id ], "date<": MOCK_DATE.end_of_year
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 4
        expect( body.first['id'] ).to eq session.id
        expect( body.last['id'] ).to eq session4.id

        get "/api/contents", timeslots_ids: [ ts.id ], "date>": MOCK_DATE.end_of_week
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 3
        expect( body.first['id'] ).to eq session2.id
        expect( body.last['id'] ).to eq session4.id

        get "/api/contents", timeslots_ids: [ ts.id ], "date>": MOCK_DATE.end_of_week, "date<": MOCK_DATE.end_of_year
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 3
        expect( body.first['id'] ).to eq session2.id
        expect( body.last['id'] ).to eq session4.id

        get "/api/contents", timeslots_ids: [ ts.id ], "date>": MOCK_DATE.end_of_week, "date<": MOCK_DATE.end_of_month
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 2
        expect( body.first['id'] ).to eq session2.id
        expect( body.last['id'] ).to eq session3.id

        session&.destroy
        session2&.destroy
        session3&.destroy
        session4&.destroy
    end

    it 'modifies a Content' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        ts2 = Timeslot.create( structure_id: MOCK_UAI,
                               group_id: 999_999,
                               subject_id: "SUBJECT_ID",
                               weekday: Time.now.wday,
                               start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                               end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )

        trail = Trail.create( label: "prout" )

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session2 = Content[id: JSON.parse( last_response.body ).first['id'] ]

        dt = DateTime.now
        put "/api/contents/#{session.id}",
            timeslot_id: ts2.id,
            date: MOCK_DATE.end_of_year,
            atime: dt,
            content: "#{MOCK_CONTENT}#{MOCK_CONTENT}",
            load: 2,
            trails_ids: [trail.id],
            type: "assignment",
            parent_content_id: session2.id,
            assignment_type: "DM",
            attachments: [ { type: "DOC", name: "tralala", external_id: "tralala" },
                           { type: "URL", name: "trilili", external_id: "trilili" } ],
            users_ids: [ MOCK_USER_ELV['id'] ]

        body = JSON.parse( last_response.body )
        created_content = Content[id: body['id']]

        expect( body['id'] ).to eq session.id
        expect( body['timeslot_id'] ).to eq ts2.id
        expect( body['date'] ).to eq MOCK_DATE.end_of_year.strftime("%F")
        expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
        expect( body['dtime'] ).to be nil
        expect( body['vtime'] ).to be nil
        expect( DateTime.parse( body['atime'] ).iso8601 ).to eq dt.iso8601
        expect( body['load'] ).to eq 2
        expect( body['type'] ).to eq "assignment"
        expect( created_content.attachments.length ).to eq 2
        expect( created_content.attachments.first.type ).to eq "DOC"
        expect( created_content.attachments.first.name ).to eq "tralala"
        expect( created_content.attachments.first.external_id ).to eq "tralala"
        expect( created_content.attachments.last.type ).to eq "URL"
        expect( created_content.attachments.last.name ).to eq "trilili"
        expect( created_content.attachments.last.external_id ).to eq "trilili"
        expect( created_content.users.length ).to eq 1
        expect( created_content.users.first.uid ).to eq MOCK_USER_ELV['id']

        session&.remove_all_attachments
        session&.remove_all_users
        session&.remove_all_trails
        session&.destroy
        session2&.destroy
        trail&.destroy
        ts2&.destroy
    end

    it 'marks an Assignment as done' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "assignment" } ]
        assignment = Content[id: JSON.parse( last_response.body ).first['id'] ]

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        put "/api/contents/#{assignment.id}",
            rtime: true,
            author_id: u_id

        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq assignment.id
        expect( body['stime'] ).to_not be nil

        assignment&.destroy
    end

    it 'FORBIDS marking a Session as validated when not DIR' do
        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        put "/api/contents/#{session.id}",
            vtime: true

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        put "/api/contents/#{session.id}",
            vtime: true

        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq session.id
        expect( body['vtime'] ).to be nil

        session&.destroy
    end

    it 'marks a Session as seen' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        $mock_user = MOCK_USER_DIR  # rubocop:disable Style/GlobalVars

        put "/api/contents/#{session.id}",
            stime: true

        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq session.id
        expect( body['stime'] ).to_not be nil

        session&.destroy
    end

    it 'marks a Session as unseen' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        $mock_user = MOCK_USER_DIR  # rubocop:disable Style/GlobalVars

        put "/api/contents/#{session.id}",
            stime: false

        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq session.id
        expect( body['stime'] ).to be nil

        session&.destroy
    end

    it 'marks a Session as validated' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        $mock_user = MOCK_USER_DIR  # rubocop:disable Style/GlobalVars

        put "/api/contents/#{session.id}",
            vtime: true

        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq session.id
        expect( body['vtime'] ).to_not be nil

        session&.destroy
    end

    it 'marks a Session as unvalidated' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        $mock_user = MOCK_USER_DIR  # rubocop:disable Style/GlobalVars

        put "/api/contents/#{session.id}",
            vtime: false

        body = JSON.parse( last_response.body )

        expect( body['id'] ).to eq session.id
        expect( body['vtime'] ).to be nil

        session&.destroy
    end

    it 'FORBIDS deletion when not author' do
        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        delete "/api/contents/#{session.id}"
        expect( last_response.status ).to eq 401

        session&.destroy
    end

    it 'deletes a Content by id' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/contents/', contents: [ { author_id: u_id, timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT, type: "session" } ]
        session = Content[id: JSON.parse( last_response.body ).first['id'] ]

        delete "/api/contents/#{session.id}"

        body = JSON.parse( last_response.body )
        expect( body['dtime'] ).to_not be nil
        expect( body['mtime'] ).to_not be nil
        expect( body['id'] ).to eq session.id
        expect( body['timeslot_id'] ).to eq ts.id

        session&.destroy
    end
end
