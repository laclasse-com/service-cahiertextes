# frozen_string_literal: true

Sequel.migration do
    change do
        puts '066_rename_assignment_type-to-subtype.rb'

        alter_table( :contents ) do
            rename_column :assignment_type, :subtype
        end
    end
end
