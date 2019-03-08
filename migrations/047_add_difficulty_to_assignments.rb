# frozen_string_literal: true

Sequel.migration do
    change do
        puts '047_add_difficulty_to_assignments.rb'

        alter_table( :assignments ) do
            add_column :difficulty, Integer
        end
    end
end
