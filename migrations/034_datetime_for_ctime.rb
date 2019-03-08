# frozen_string_literal: true

Sequel.migration do
    change do
        puts '034_datetime_for_ctime.rb'

        alter_table( :imports ) do
            set_column_type :ctime, DateTime
        end
    end
end
