# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :imports ) do
            set_column_type :ctime, DateTime
        end
    end
end
puts '034_datetime_for_ctime.rb'
