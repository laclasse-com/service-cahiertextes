# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :assignments ) do
            rename_column :time_estimate, :load
        end
    end
end
puts 'applying 053_rename_time_estimate_to_load.rb'
