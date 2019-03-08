# frozen_string_literal: true

Sequel.migration do
    change do
        puts '046_optional_link_users_sessions_assignments.rb'

        create_table!( :sessions_users) do
            primary_key %i[session_id user_id]
            foreign_key :session_id, :sessions, null: false
            foreign_key :user_id, :users, null: false
        end

        create_table!( :assignments_users) do
            primary_key %i[assignment_id user_id]
            foreign_key :assignment_id, :assignments, null: false
            foreign_key :user_id, :users, null: false
        end
    end
end
