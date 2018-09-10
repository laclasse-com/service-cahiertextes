# frozen_string_literal: true

Sequel.migration do
    change do
        tables = [:imports, :timeslots, :locations, :matchables]

        tables.each do |table|
            alter_table( table ) do
                add_column( :structure_uai, String )
            end
        end

        DB[:structures].all.each do |structure|
            tables.each do |table|
                alter_table( table ) do
                    DB[ table ].where( structure_id: structure[:id] )
                               .update( structure_uai: structure[:UAI] )
                end
            end
        end

        tables.each do |table|
            alter_table( table ) do
                drop_foreign_key :structure_id
                # set_column_not_null :structure_uai

                rename_column :structure_uai, :structure_id
            end
        end

        drop_table :structures
    end
end
puts "032_drop_table_structure.rb"
