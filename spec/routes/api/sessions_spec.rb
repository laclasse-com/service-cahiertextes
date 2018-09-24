# frozen_string_literal: true

require_relative '../../test_setup'

require_relative '../../../models/session'

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

    MOCK_DATE = DateTime.now
    MOCK_CONTENT = 'test session'

    sid = -1

    it 'creates a Session' do
        post '/api/sessions/', timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT

        body = JSON.parse( last_response.body )
        sid = body['id']
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body['content'] ).to eq MOCK_CONTENT
        expect( body['vtime'] ).to be nil
    end

    it 'gets a Session by id' do
        get "/api/sessions/#{sid}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq sid
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body['content'] ).to eq MOCK_CONTENT
        expect( body['deleted'] ).to be false
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
        get "/api/sessions", 'date>' => MOCK_DATE.beginning_of_month

        body = JSON.parse( last_response.body )
        cohort = Session.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{MOCK_DATE.beginning_of_month}'" ) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Sessions by date<' do
        get "/api/sessions", 'date<' => MOCK_DATE.end_of_month

        body = JSON.parse( last_response.body )
        cohort = Session.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{MOCK_DATE.end_of_month}'" ) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Sessions by date> and date<' do
        get "/api/sessions", 'date>' => MOCK_DATE.beginning_of_month, 'date<' => MOCK_DATE.end_of_month

        body = JSON.parse( last_response.body )
        cohort = Session.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{MOCK_DATE.beginning_of_month}'" ) ).where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{MOCK_DATE.end_of_month}'" ) )
        expect( body.length ).to eq cohort.count
    end

    it 'modifies a Session' do
        put "/api/sessions/#{sid}", date: MOCK_DATE.end_of_year, content: "#{MOCK_CONTENT}#{MOCK_CONTENT}"

        body = JSON.parse( last_response.body )
        lid = body['id']
        expect( body['id'] ).to eq lid
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.end_of_year.strftime("%F")
        expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
        expect( body['deleted'] ).to be false
        expect( body['vtime'] ).to be nil
    end

    it 'CANNOT validate a Session without a vtime' do
        put "/api/sessions/#{sid}", validated: true

        body = JSON.parse( last_response.body )
        lid = body['id']
        expect( body['id'] ).to eq lid
        expect( body['deleted'] ).to be false
        expect( body['vtime'] ).to be nil
    end

    it 'validates a Session' do
        vtime = Time.now
        put "/api/sessions/#{sid}", validated: true, vtime: vtime

        body = JSON.parse( last_response.body )
        lid = body['id']
        expect( body['id'] ).to eq lid
        expect( body['deleted'] ).to be false
        expect( body['vtime'] ).to eq vtime.to_s
    end

    it 'invalidates a Session' do
        put "/api/sessions/#{sid}", validated: false

        body = JSON.parse( last_response.body )
        lid = body['id']
        expect( body['id'] ).to eq lid
        expect( body['deleted'] ).to be false
        expect( body['vtime'] ).to be nil
    end

    it 'deletes a Session by id' do
        delete "/api/sessions/#{sid}"

        body = JSON.parse( last_response.body )

        expect( body['deleted'] ).to be true
        expect( body['id'] ).to eq sid
        expect( body['timeslot_id'] ).to eq ts.id
        # expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        # expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
    end
end
