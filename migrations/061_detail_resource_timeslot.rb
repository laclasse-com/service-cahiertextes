# frozen_string_literal: true

Sequel.migration do
    change do
        puts '061_detail_resource_timeslot.rb'

        alter_table( :resources ) do
            add_foreign_key :author_id, :users
        end

        alter_table( :timeslots_resources ) do
            add_column :date, Date
            add_foreign_key :author_id, :users
            add_column :vtime, DateTime
        end
    end
end
