# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Notes' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    ts = nil
    note = nil

    before( :each ) do
        $mock_user = MOCK_USER_GENERIC

        ts = Timeslot.create( structure_id: MOCK_UAI,
                              group_id: 999_999,
                              subject_id: "SUBJECT_ID",
                              weekday: Time.now.wday,
                              start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                              end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )

        note = Note.create( timeslot_id: ts.id,
                            date: MOCK_DATE,
                            content: MOCK_CONTENT,
                            author_id: u_id,
                            ctime: Time.now )
    end

    after( :each ) do
        $mock_user = MOCK_USER_GENERIC

        ts.notes.each(&:destroy)
        ts&.destroy
    end

    it 'creates a Note' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        post '/api/notes/', notes: [ { timeslot_id: ts.id, date: MOCK_DATE, content: MOCK_CONTENT } ]

        body = JSON.parse( last_response.body )
        expect( body.first['timeslot_id'] ).to eq ts.id
        expect( body.first['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body.first['content'] ).to eq MOCK_CONTENT
        expect( body.first['author_id'] ).to eq u_id
    end

    it 'gets a Note by id' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        get "/api/notes/#{note.id}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq note.id
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        expect( body['content'] ).to eq MOCK_CONTENT
        expect( body['dtime'] ).to be nil
        expect( body['author_id'] ).to eq u_id
    end

    it 'gets Notes by timeslot_id' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        get "/api/notes", timeslots_ids: [ ts.id ]

        body = JSON.parse( last_response.body )
        cohort = Note.where(timeslot_id: [ts.id] )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Notes by date' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        get "/api/notes", date: MOCK_DATE

        body = JSON.parse( last_response.body )
        cohort = Note.where(date: MOCK_DATE.strftime("%F") )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Notes by date>' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        get "/api/notes", 'date>' => MOCK_DATE.beginning_of_year

        body = JSON.parse( last_response.body )
        cohort = Note.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{MOCK_DATE.beginning_of_year}'" ) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Notes by date<' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        get "/api/notes", 'date<' => MOCK_DATE.end_of_year

        body = JSON.parse( last_response.body )
        cohort = Note.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{MOCK_DATE.end_of_year}'" ) )
        expect( body.length ).to eq cohort.count
    end

    it 'gets Notes by date> and date<' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        get "/api/notes", 'date>' => MOCK_DATE.beginning_of_year, 'date<' => MOCK_DATE.end_of_year

        body = JSON.parse( last_response.body )
        cohort = Note.where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') >= '#{MOCK_DATE.beginning_of_year}'" ) ).where( Sequel.lit( "DATE_FORMAT( date, '%Y-%m-%d') <= '#{MOCK_DATE.end_of_year}'" ) )
        expect( body.length ).to eq cohort.count
    end

    it 'FORBIDS update when not author' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        put "/api/notes/#{note.id}", date: MOCK_DATE.end_of_year, content: "#{MOCK_CONTENT}#{MOCK_CONTENT}"

        expect( last_response.status ).to eq 401
    end

    it 'modifies a Note' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        put "/api/notes/#{note.id}", date: MOCK_DATE.end_of_year, content: "#{MOCK_CONTENT}#{MOCK_CONTENT}"

        body = JSON.parse( last_response.body )
        note.id = body['id']
        expect( body['id'] ).to eq note.id
        expect( body['timeslot_id'] ).to eq ts.id
        expect( body['date'] ).to eq MOCK_DATE.end_of_year.strftime("%F")
        expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
        expect( body['dtime'] ).to be nil
        expect( body['vtime'] ).to be nil
    end

    it 'FORBIDS deletion when not author' do
        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        delete "/api/notes/#{note.id}"

        expect( last_response.status ).to eq 401
    end

    it 'deletes a Note by id' do
        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        delete "/api/notes/#{note.id}"

        body = JSON.parse( last_response.body )

        expect( body['dtime'] ).to_not be nil
        expect( body['id'] ).to eq note.id
        expect( body['timeslot_id'] ).to eq ts.id
        # expect( body['date'] ).to eq MOCK_DATE.strftime("%F")
        # expect( body['content'] ).to eq "#{MOCK_CONTENT}#{MOCK_CONTENT}"
    end
end
