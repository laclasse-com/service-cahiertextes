# frozen_string_literal: true

Sequel.migration do
    change do
        puts '045_rename_table_user_parameters.rb'

        rename_table( :users_parameters, :users )
    end
end
