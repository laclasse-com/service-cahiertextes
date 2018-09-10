# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :textbooks ) do
            drop_column :schoolyear_start
            drop_column :schoolyear_end
        end

        alter_table( :structures ) do
            drop_column :schoolyear_start
            drop_column :schoolyear_end
            drop_column :first_day_of_first_week
        end
    end
end
puts "031_drop_column_schoolyear_and_fdofw.rb"
