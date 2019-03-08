# frozen_string_literal: true

Sequel.migration do
    change do
        puts '038_change_imports.rb'

        alter_table( :imports ) do
            drop_column :comment
            add_column :author_id, String
        end
    end
end
