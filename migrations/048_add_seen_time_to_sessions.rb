# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :sessions ) do
            add_column :stime, DateTime # seen time
        end
    end
end
puts 'applying 048_add_seen_time_to_sessions.rb'
