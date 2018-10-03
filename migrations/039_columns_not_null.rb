# frozen_string_literal: true

Sequel.migration do
    change do
        # structure_id
        alter_table( :timeslots ) do
            set_column_not_null :structure_id
        end

        alter_table( :matchables ) do
            set_column_not_null :structure_id
        end

        DB[:resources].where( structure_id: nil ).all do |r|
            tid = DB[:timeslots_resources].where(resource_id: r[:id])
                                          .naked
                                          .first[:timeslot_id]
            sid = DB[:timeslots].where(id: tid )
                                .select(:structure_id)
                                .naked
                                .first[:structure_id]

            DB[:resources].where(id: r[:id])
                          .update(structure_id: sid )
        end
        alter_table( :resources ) do
            set_column_not_null :structure_id
        end

        alter_table( :imports ) do
            set_column_not_null :structure_id
        end

        # known_id
        alter_table( :matchables ) do
            set_column_not_null :known_id
        end

        # session_id
        p DB[:assignments].all
        DB[:assignments].where(session_id: nil).update(session_id: 0)
        alter_table( :assignments ) do
            set_column_not_null :session_id
        end

        # imports.*
        DB[:imports].update( type: "pronote", author_id: "" )
        alter_table( :imports ) do
            set_column_not_null :ctime
            set_column_not_null :type
            set_column_not_null :author_id
        end
    end
end
puts '039_columns_not_null.rb'
