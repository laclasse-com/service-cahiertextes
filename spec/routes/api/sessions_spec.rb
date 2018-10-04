# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Sessions' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    ts = nil

    before( :all ) do
        ts = Timeslot.create( structure_id: MOCK_UAI,
                              group_id: 999_999,
                              subject_id: "SUBJECT_ID",
                              weekday: Time.now.wday,
                              start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                              end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
    end

    after( :all ) do
        ts.sessions.each(&:destroy)
        ts&.destroy
    end

    sid = -1

    it 'FORBIDS creation when not ENS DOC' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        post '/api/sessions/', timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'creates a Session' do
        post '/api/sessions/', timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT

        body = JSON.parse( last_response.body )
        sid = body['id']
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body['content'] ).to eq MOCK_CONTENT
        expect( body['vtime'] ).to be nil
    end

    it 'FORBIDS getting from a group the user does not belong to' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars
        $mock_user['groups'].first['group_id'] = MOCK_GROUP_ID - 1  # rubocop:disable Style/GlobalVars

        get "/api/sessions/#{sid}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'ALLOWS getting from a group the user does not belong to but is ADM DIR of structure' do
        $mock_user = MOCK_USER_ADM  # rubocop:disable Style/GlobalVars

        get "/api/sessions/#{sid}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq sid
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body['content'] ).to eq MOCK_CONTENT
        expect( body['dtime'] ).to be nil

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'gets a Session by id' do
        get "/api/sessions/#{sid}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq sid
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body['content'] ).to eq MOCK_CONTENT
        expect( body['dtime'] ).to be nil
    end

    it 'gets Sessions by timeslot_id' do
        get "/api/sessions", timeslots_ids: [ ts.id ]

        body = JSON.parse( last_response.body )
        cohort = Session.where(timeslot_id: [ts.id] )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Sessions by group_id' do
        get "/api/sessions", groups_ids: [ 999_999 ]

        body = JSON.parse( last_response.body )
        cohort = Session.where( timeslot_id: Timeslot.select(:id).where(group_id: [ 999_999 ]) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Sessions by author_id' do
        get "/api/sessions", authors_ids: [ LaClasse::Helpers::User.user['id'] ]

        body = JSON.parse( last_response.body )
        cohort = Session.where(author_id: [ LaClasse::Helpers::User.user['id'] ] )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Sessions by date' do
        get "/api/sessions", date: MOCK_DATE

        body = JSON.parse( last_response.body )
        cohort = Session.where(date: MOCK_DATE.strftime("%F") )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Sessions by date>' do
        get "/api/sessions", 'date>' => MOCK_DATE.beginning_of_year

        body = JSON.parse( last_response.body )
        cohort = Session.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{MOCK_DATE.beginning_of_year}'" ) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Sessions by date<' do
        get "/api/sessions", 'date<' => MOCK_DATE.end_of_year

        body = JSON.parse( last_response.body )
        cohort = Session.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{MOCK_DATE.end_of_year}'" ) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Sessions by date> and date<' do
        get "/api/sessions", 'date>' => MOCK_DATE.beginning_of_year, 'date<' => MOCK_DATE.end_of_year

        body = JSON.parse( last_response.body )
        cohort = Session.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{MOCK_DATE.beginning_of_year}'" ) ).where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{MOCK_DATE.end_of_year}'" ) )
        expect( body.length ).to eq cohort.count
    end

    it 'FORBIDS update when not ENS DOC or author' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        put "/api/sessions/#{sid}", date: MOCK_DATE.end_of_year, content: "#{MOCK_CONTENT}#{MOCK_CONTENT}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'modifies a Session' do
        put "/api/sessions/#{sid}", date: MOCK_DATE.end_of_year, content: "#{MOCK_CONTENT}#{MOCK_CONTENT}"

        body = JSON.parse( last_response.body )
        sid = body['id']
        expect( body['id'] ).to eq sid
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.end_of_year.strftime("%F")
        expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
        expect( body['dtime'] ).to be nil
        expect( body['vtime'] ).to be nil
    end

    it 'CANNOT validate a Session without a vtime' do
        put "/api/sessions/#{sid}", validated: true

        body = JSON.parse( last_response.body )
        sid = body['id']
        expect( body['id'] ).to eq sid
        expect( body['dtime'] ).to be nil
        expect( body['vtime'] ).to be nil
    end

    it 'CANNOT validates a Session when not DIR' do
        $mock_user = MOCK_USER_ADM  # rubocop:disable Style/GlobalVars

        vtime = Time.now
        put "/api/sessions/#{sid}", validated: true, vtime: vtime

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'validates a Session' do
        $mock_user = MOCK_USER_DIR  # rubocop:disable Style/GlobalVars

        vtime = Time.now
        put "/api/sessions/#{sid}", validated: true, vtime: vtime

        body = JSON.parse( last_response.body )
        sid = body['id']
        expect( body['id'] ).to eq sid
        expect( body['dtime'] ).to be nil
        expect( body['vtime'] ).to eq vtime.to_s

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'CANNOT validates a Session when not DIR' do
        $mock_user = MOCK_USER_ADM  # rubocop:disable Style/GlobalVars

        put "/api/sessions/#{sid}", validated: false

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'invalidates a Session' do
        $mock_user = MOCK_USER_DIR  # rubocop:disable Style/GlobalVars

        put "/api/sessions/#{sid}", validated: false

        body = JSON.parse( last_response.body )
        sid = body['id']
        expect( body['id'] ).to eq sid
        expect( body['dtime'] ).to be nil
        expect( body['vtime'] ).to be nil

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'copies a session to a different timeslot' do
        ts2 = Timeslot.create( structure_id: MOCK_UAI,
                               group_id: 111_111,
                               subject_id: "SUBJECT_ID",
                               weekday: Time.now.wday + 1,
                               start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                               end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )

        copy_date = DateTime.now + 1.day

        post "/api/sessions/#{sid}/copy_to/timeslot/#{ts2.id}/date/#{copy_date}"
        # body = JSON.parse( last_response.body )

        expect( ts2.sessions.length ).to eq 1
        expect( ts2.sessions.first.id ).to_not eq sid
        expect( ts2.sessions.first.timeslot_id ).to eq ts2.id
        expect( ts2.sessions.first.author_id ).to eq Session[sid].author_id
    end

    it 'FORBIDS deletion when not ENS DOC or author' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        delete "/api/sessions/#{sid}"

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'deletes a Session by id' do
        delete "/api/sessions/#{sid}"

        body = JSON.parse( last_response.body )

        expect( body['dtime'] ).to_not be nil
        expect( body['id'] ).to eq sid
        expect( body['timeslot_id'] ).to eq ts.id
        # expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        # expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
    end
end
