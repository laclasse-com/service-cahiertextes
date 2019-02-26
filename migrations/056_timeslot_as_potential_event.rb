# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :timeslots ) do
            set_column_allow_null :structure_id
            set_column_allow_null :group_id
            set_column_allow_null :subject_id
            set_column_allow_null :active_weeks
            set_column_allow_null :weekday

            add_column :date, Date
            add_column :title, String
            add_foreign_key :author_id, :users
        end

        create_table!( :timeslots_users) do
            primary_key %i[timeslot_id user_id]
            foreign_key :timeslot_id, :timeslots, null: false
            foreign_key :user_id, :users, null: false
        end
    end
end
puts 'applying 056_timeslot_as_potential_event.rb'
