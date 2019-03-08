# frozen_string_literal: true

Sequel.migration do
    change do
        puts '057_rename_assignment_date_due_to_date.rb'

        alter_table( :assignments ) do
            rename_column :date_due, :date
        end
    end
end
