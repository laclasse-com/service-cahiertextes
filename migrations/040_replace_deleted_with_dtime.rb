# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :timeslots ) do
            drop_column :deleted
        end

        alter_table( :sessions ) do
            add_column :dtime, DateTime, null: true
        end
        DB[:sessions].where( deleted: true ).update( dtime: :mtime )
        alter_table( :sessions ) do
            drop_column :deleted
        end

        alter_table( :assignments ) do
            add_column :dtime, DateTime, null: true
        end
        DB[:assignments].where( deleted: true ).update( dtime: :mtime )
        alter_table( :assignments ) do
            drop_column :deleted
        end
    end
end
puts '040_replace_deleted_with_dtime.rb'
