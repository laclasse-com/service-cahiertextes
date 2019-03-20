# frozen_string_literal: true

Sequel.migration do
    change do
        puts '062_rename_table_timeslots_resources_into_reservations.rb'

        create_table!(:reservations) do
            primary_key :id
            foreign_key :timeslot_id, :timeslots, null: false
            foreign_key :resource_id, :resources, null: false
            foreign_key :author_id, :users

            Bignum :active_weeks
            Date :date
            DateTime :vtime
        end

        DB[:timeslots_resources].all.each do |reservation|
            DB[:reservations].insert( %w[timeslot_id resource_id active_weeks],
                                      [reservation[:timeslot_id], reservation[:resource_id], reservation[:active_weeks]] )
        end

        drop_table :timeslots_resources
    end
end
