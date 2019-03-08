# frozen_string_literal: true

Sequel.migration do
    change do
        puts '012_add_comment_to_imports.rb'

        alter_table( :imports ) do
            add_column :comment, String, null: true
        end
    end
end
