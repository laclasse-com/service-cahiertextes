# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :imports ) do
            rename_column( :date_import, :ctime )
        end
    end
end
puts "024_rename_imports_date_import.rb"
