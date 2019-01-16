# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :assignments ) do
            add_column :difficulty, Integer
        end
    end
end
puts 'applying 047_add_difficulty_to_assignments.rb'
