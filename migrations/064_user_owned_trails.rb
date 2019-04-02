# frozen_string_literal: true

Sequel.migration do
    change do
        puts '064_user_owned_trails.rb'

        alter_table( :trails ) do
            add_foreign_key :author_id, :users
            add_column :private, :boolean, default: false
        end

        DB[:trails].update( private: false )

        alter_table( :trails ) do
            set_column_not_null :private
        end
    end
end
