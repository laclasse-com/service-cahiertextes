# frozen_string_literal: true

Sequel.migration do
    change do
        puts '051_add_show_after_date_sessions_assignments.rb'

        [:sessions, :assignments].each do |table|
            alter_table( table ) do
                add_column :atime, DateTime # ActiveTIME
            end
        end
    end
end
