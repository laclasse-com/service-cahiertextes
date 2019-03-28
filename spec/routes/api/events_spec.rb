# frozen_string_literal: true

require_relative '../../test_setup'

describe 'Routes::Api::Events' do
    include Rack::Test::Methods

    def app
        CdTServer.new
    end

    it 'creates an Event' do
        date = DateTime.now.to_date
        title = "title"

        post '/api/timeslots/', timeslots: [ { date: date,
                                               title: title,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME } ]

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq 1
        expect( body.first['date'] ).to eq date.to_s
        expect( body.first['title'] ).to eq title
        expect( body.first['start_time'] ).to eq MOCK_START_TIME
        expect( body.first['end_time'] ).to eq MOCK_END_TIME
        expect( body.first['author_id'] ).to be u_id

        Timeslot[id: body.first['id']]&.destroy
    end

    it 'creates an Event with contributors' do
        date = DateTime.now.to_date
        title = "title"

        post '/api/timeslots/', timeslots: [ { date: date,
                                               title: title,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME,
                                               contributors_uids: [ MOCK_USER_ENS['id'], MOCK_USER_ELV['id'] ]} ]

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq 1
        expect( body.first['date'] ).to eq date.to_s
        expect( body.first['title'] ).to eq title
        expect( body.first['start_time'] ).to eq MOCK_START_TIME
        expect( body.first['end_time'] ).to eq MOCK_END_TIME
        expect( body.first['author_id'] ).to be u_id
        expect( Timeslot[id: body.first['id']].contributors.length ).to eq 2

        t = Timeslot[id: body.first['id']]
        t&.remove_all_contributors
        t&.destroy
    end

    it 'creates multiple Events with and without contributors' do
        date = DateTime.now.to_date
        title = "title"

        post '/api/timeslots/', timeslots: [ { date: date,
                                               title: title,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME},
                                             { date: date,
                                               title: "#{title}#{title}",
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME,
                                               contributors_uids: [ MOCK_USER_ENS['id'], MOCK_USER_ELV['id'] ]} ]

        body = JSON.parse( last_response.body )

        expect( body.length ).to eq 2
        expect( body.first['date'] ).to eq date.to_s
        expect( body.first['title'] ).to eq title
        expect( body.first['start_time'] ).to eq MOCK_START_TIME
        expect( body.first['end_time'] ).to eq MOCK_END_TIME
        expect( body.first['author_id'] ).to be u_id
        expect( Timeslot[id: body.last['id']].contributors.length ).to eq 2

        body.each do |e|
            t = Timeslot[id: e['id']]
            t&.remove_all_contributors
            t&.destroy
        end
    end

    it 'gets a Timeslot by id' do
        date = DateTime.now.to_date
        title = "title"
        post '/api/timeslots/', timeslots: [ { date: date,
                                               title: title,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME } ]
        event = JSON.parse( last_response.body ).first

        get "/api/timeslots/#{event['id']}"

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq event['id']
        expect( body['date'] ).to eq date.to_s
        expect( body['title'] ).to eq title
        expect( body['start_time'] ).to eq MOCK_START_TIME
        expect( body['end_time'] ).to eq MOCK_END_TIME

        Timeslot[id: event['id']]&.destroy
    end

    it 'modifies a Timeslot' do
        date = DateTime.now.to_date
        title = "title"

        post '/api/timeslots/', timeslots: [ { date: date,
                                               title: title,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME,
                                               contributors_uids: [ MOCK_USER_ENS['id'], MOCK_USER_ELV['id'] ]} ]
        event = JSON.parse( last_response.body ).first

        put "/api/timeslots/#{event['id']}",
            title: "tralala",
            start_time: MOCK_START_TIME,
            end_time: MOCK_END_TIME

        body = JSON.parse( last_response.body )
        expect( body['id'] ).to eq event['id']
        expect( body['title'] ).to eq "tralala"
        expect( body['start_time'] ).to eq MOCK_START_TIME
        expect( body['end_time'] ).to eq MOCK_END_TIME

        Timeslot[id: event['id']]&.remove_all_contributors
        Timeslot[id: event['id']]&.destroy
    end

    it 'FORBIDS update when not author' do
        date = DateTime.now.to_date
        title = "title"

        post '/api/timeslots/', timeslots: [ { date: date,
                                               title: title,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME,
                                               contributors_uids: [ MOCK_USER_ENS['id'], MOCK_USER_ELV['id'] ]} ]
        event = JSON.parse( last_response.body ).first

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars

        put "/api/timeslots/#{event['id']}",
            group_id: MOCK_GROUP_ID + 1,
            subject_id: "#{MOCK_SUBJECT_ID}2",
            weekday: MOCK_WEEKDAY + 1,
            start_time: MOCK_START_TIME,
            end_time: MOCK_END_TIME

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars

        Timeslot[id: event['id']]&.remove_all_contributors
        Timeslot[id: event['id']]&.destroy
    end

    it 'deletes a Timeslot as author' do
        date = DateTime.now.to_date
        title = "title"
        post '/api/timeslots/', timeslots: [ { date: date,
                                               title: title,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME } ]
        event = JSON.parse( last_response.body ).first

        delete "/api/timeslots/#{event['id']}", dtime: Time.now

        expect( Timeslot[id: event['id']].dtime ).to_not be nil
    end

    it 'deletes a Timeslot as contributor' do
        date = DateTime.now.to_date
        title = "title"

        post '/api/timeslots/', timeslots: [ { date: date,
                                               title: title,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME,
                                               contributors_uids: [ MOCK_USER_ENS['id'], MOCK_USER_ELV['id'] ]} ]
        event = JSON.parse( last_response.body ).first

        $mock_user = MOCK_USER_ELV  # rubocop:disable Style/GlobalVars
        delete "/api/timeslots/#{event['id']}", dtime: Time.now

        expect( Timeslot[id: event['id']].dtime ).to be nil
    end

    it 'FORBIDS deletion when neither author nor contributor' do
        date = DateTime.now.to_date
        title = "title"

        post '/api/timeslots/', timeslots: [ { date: date,
                                               title: title,
                                               start_time: MOCK_START_TIME,
                                               end_time: MOCK_END_TIME,
                                               contributors_uids: [ MOCK_USER_ENS['id'] ]} ]
        event = JSON.parse( last_response.body ).first

        $mock_user = MOCK_USER_DIR  # rubocop:disable Style/GlobalVars

        delete "/api/timeslots/#{event['id']}", dtime: Time.now

        expect( last_response.status ).to eq 401

        $mock_user = MOCK_USER_GENERIC  # rubocop:disable Style/GlobalVars
    end
end
