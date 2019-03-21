# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Reservations' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'creates Reservations' do
        timeslot = Timeslot.create( structure_id: MOCK_UAI,
                                    group_id: 999_999,
                                    subject_id: "SUBJECT_ID",
                                    weekday: Time.now.wday,
                                    start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                                    end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        resource = Resource.create( label: "test",
                                    structure_id: MOCK_UAI,
                                    type: "test" )

        $mock_user = MOCK_USER_ENS  # rubocop:disable Style/GlobalVars

        post '/api/reservations/', reservations: [ { timeslot_id: timeslot.id, resource_id: resource.id, date: Time.now.strftime("%F") } ]

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq 1
        expect( body.first['author_id'] ).to eq u_id
        expect( body.first['vtime'] ).to be_nil

        Reservation.where(id: body.map { |l| l['id'] })&.destroy
        timeslot&.destroy
        resource&.destroy

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end

    it 'validates a Reservation' do
        timeslot = Timeslot.create( structure_id: MOCK_UAI,
                                    group_id: 999_999,
                                    subject_id: "SUBJECT_ID",
                                    weekday: Time.now.wday,
                                    start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                                    end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        resource = Resource.create( label: "test",
                                    structure_id: MOCK_UAI,
                                    type: "test" )

        post '/api/reservations/', reservations: [ { timeslot_id: timeslot.id, resource_id: resource.id, date: Time.now.strftime("%F") } ]
        body = JSON.parse( last_response.body )

        put "/api/reservations/#{body.first['id']}", vtime: true
        body = JSON.parse( last_response.body )

        expect( body['vtime'] ).to be true

        Reservation.where(id: body['id'])&.destroy
        timeslot&.destroy
        resource&.destroy
    end

    it 'invalidates a Reservation' do
        timeslot = Timeslot.create( structure_id: MOCK_UAI,
                                    group_id: 999_999,
                                    subject_id: "SUBJECT_ID",
                                    weekday: Time.now.wday,
                                    start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                                    end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        resource = Resource.create( label: "test",
                                    structure_id: MOCK_UAI,
                                    type: "test" )

        post '/api/reservations/', reservations: [ { timeslot_id: timeslot.id, resource_id: resource.id, date: Time.now.strftime("%F") } ]
        body = JSON.parse( last_response.body )

        put "/api/reservations/#{body.first['id']}", vtime: true

        put "/api/reservations/#{body.first['id']}", vtime: false
        body = JSON.parse( last_response.body )

        expect( body['vtime'] ).to be false

        Reservation.where(id: body['id'])&.destroy
        timeslot&.destroy
        resource&.destroy
    end

    it 'edits a Reservation' do
        timeslot = Timeslot.create( structure_id: MOCK_UAI,
                                    group_id: 999_999,
                                    subject_id: "SUBJECT_ID",
                                    weekday: Time.now.wday,
                                    start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                                    end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        resource = Resource.create( label: "test",
                                    structure_id: MOCK_UAI,
                                    type: "test" )

        post '/api/reservations/', reservations: [ { timeslot_id: timeslot.id, resource_id: resource.id, date: Time.now.strftime("%F") } ]
        reservation = JSON.parse( last_response.body )

        put "/api/reservations/#{reservation.first['id']}", date: Time.now.end_of_year.strftime("%F")
        body = JSON.parse( last_response.body )

        expect( body['date'] ).to eq Time.now.end_of_year.strftime("%F")

        put "/api/reservations/#{reservation.first['id']}", active_weeks: 300_803
        body = JSON.parse( last_response.body )

        expect( body['active_weeks'] ).to eq 300_803

        put "/api/reservations/#{reservation.first['id']}",
            date: Time.now.end_of_year.strftime("%F"),
            active_weeks: 300_803
        body = JSON.parse( last_response.body )

        expect( body['date'] ).to be_nil
        expect( body['active_weeks']).to eq 300_803

        timeslot2 = Timeslot.create( structure_id: MOCK_UAI,
                                     group_id: 999_999,
                                     subject_id: "SUBJECT_ID2",
                                     weekday: Time.now.wday,
                                     start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                                     end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        resource2 = Resource.create( label: "test2",
                                     structure_id: MOCK_UAI,
                                     type: "test" )

        put "/api/reservations/#{reservation.first['id']}", timeslot_id: timeslot2.id, resource_id: resource2.id
        body = JSON.parse( last_response.body )

        expect( body['timeslot_id'] ).to eq timeslot2.id
        expect( body['resource_id'] ).to eq resource2.id

        Reservation.where(id: body['id'])&.destroy
        timeslot&.destroy
        resource&.destroy
        timeslot2&.destroy
        resource2&.destroy
    end

    it 'gets a Reservation by id' do
        timeslot = Timeslot.create( structure_id: MOCK_UAI,
                                    group_id: 999_999,
                                    subject_id: "SUBJECT_ID",
                                    weekday: Time.now.wday,
                                    start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                                    end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        resource = Resource.create( label: "test",
                                    structure_id: MOCK_UAI,
                                    type: "test" )

        post '/api/reservations/', reservations: [ { timeslot_id: timeslot.id, resource_id: resource.id, date: Time.now.strftime("%F") } ]
        body = JSON.parse( last_response.body )

        get "/api/reservations/#{body.first['id']}"
        body = JSON.parse( last_response.body )

        expect( body['author_id'] ).to eq u_id
        expect( body['vtime'] ).to be_nil
        expect( body['timeslot_id'] ).to eq timeslot.id
        expect( body['resource_id'] ).to eq resource.id

        Reservation.where(id: body['id'])&.destroy
        timeslot&.destroy
        resource&.destroy
    end

    it 'gets a Reservation by timeslot_id and/or resource_id and vtime' do
        timeslot = Timeslot.create( structure_id: MOCK_UAI,
                                    group_id: 999_999,
                                    subject_id: "SUBJECT_ID",
                                    weekday: Time.now.wday,
                                    start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                                    end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        timeslot2 = Timeslot.create( structure_id: MOCK_UAI,
                                     group_id: 999_999,
                                     subject_id: "SUBJECT_ID2",
                                     weekday: Time.now.wday,
                                     start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                                     end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        resource = Resource.create( label: "test",
                                    structure_id: MOCK_UAI,
                                    type: "test" )
        resource2 = Resource.create( label: "test2",
                                     structure_id: MOCK_UAI,
                                     type: "test" )
        reservation = Reservation.create( timeslot_id: timeslot.id, resource_id: resource.id )
        reservation2 = Reservation.create( timeslot_id: timeslot2.id, resource_id: resource.id )
        reservation3 = Reservation.create( timeslot_id: timeslot.id, resource_id: resource2.id )
        reservation4 = Reservation.create( timeslot_id: timeslot2.id, resource_id: resource2.id )
        reservation5 = Reservation.create( timeslot_id: timeslot.id, resource_id: resource.id, vtime: DateTime.now )

        get "/api/reservations/", timeslots_ids: [timeslot.id]
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 3
        expect( body.map { |r| r['id'] }.sort ).to eq [reservation.id, reservation3.id, reservation5.id]

        get "/api/reservations/", timeslots_ids: [timeslot2.id]
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 2
        expect( body.map { |r| r['id'] }.sort ).to eq [reservation2.id, reservation4.id]

        get "/api/reservations/", timeslots_ids: [timeslot.id, timeslot2.id]
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 5
        expect( body.map { |r| r['id'] }.sort ).to eq [reservation.id, reservation2.id, reservation3.id, reservation4.id, reservation5.id]

        get "/api/reservations/", timeslots_ids: [timeslot.id, timeslot2.id], vtime: true
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 1
        expect( body.first['id'] ).to eq reservation5.id

        get "/api/reservations/", timeslots_ids: [timeslot2.id], vtime: true
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 0

        get "/api/reservations/", resources_ids: [resource.id]
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 3
        expect( body.map { |r| r['id'] }.sort ).to eq [reservation.id, reservation2.id, reservation5.id]

        get "/api/reservations/", resources_ids: [resource2.id]
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 2
        expect( body.map { |r| r['id'] }.sort ).to eq [reservation3.id, reservation4.id]

        get "/api/reservations/", resources_ids: [resource.id, resource2.id]
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 5
        expect( body.map { |r| r['id'] }.sort ).to eq [reservation.id, reservation2.id, reservation3.id, reservation4.id, reservation5.id]

        get "/api/reservations/", resources_ids: [resource.id, resource2.id], vtime: true
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 1
        expect( body.first['id'] ).to eq reservation5.id

        get "/api/reservations/", resources_ids: [resource2.id], vtime: true
        body = JSON.parse( last_response.body )
        expect( body.length ).to eq 0

        reservation&.destroy
        reservation2&.destroy
        reservation3&.destroy
        reservation4&.destroy
        reservation5&.destroy
        timeslot&.destroy
        resource&.destroy
        timeslot2&.destroy
        resource2&.destroy
    end

    it 'deletes a Reservation' do
        timeslot = Timeslot.create( structure_id: MOCK_UAI,
                                    group_id: 999_999,
                                    subject_id: "SUBJECT_ID",
                                    weekday: Time.now.wday,
                                    start_time: Time.now.strftime( "2000-01-01T%H:00:00+01:00" ),
                                    end_time: Time.now.strftime( "2000-01-01T%H:30:00+01:00" ) )
        resource = Resource.create( label: "test",
                                    structure_id: MOCK_UAI,
                                    type: "test" )

        post '/api/reservations/', reservations: [ { timeslot_id: timeslot.id, resource_id: resource.id, date: Time.now.strftime("%F") } ]
        body = JSON.parse( last_response.body )

        delete "/api/reservations/#{body.first['id']}"
        expect( last_response.body ).to be_empty
        expect( Reservation[id: body.first['id']] ).to be_nil

        timeslot&.destroy
        resource&.destroy
    end
end
