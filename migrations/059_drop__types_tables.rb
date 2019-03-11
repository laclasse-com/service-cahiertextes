# frozen_string_literal: true

Sequel.migration do
    change do
        puts '059_drop__types_tables.rb'

        # attachment_types
        alter_table(:attachments) do
            add_column :type, String
        end
        DB[:attachment_types].all.each do |at|
            DB[:attachments].where(attachment_type_id: at[:id]).update(type: at[:label])
        end
        alter_table(:attachments) do
            drop_foreign_key :attachment_type_id
            set_column_not_null :type
        end
        drop_table(:attachment_types)

        # assignment_types
        alter_table(:timeslot_contents) do
            add_column :assignment_type, String
        end
        DB[:assignment_types].all.each do |at|
            DB[:timeslot_contents].where(assignment_type_id: at[:id]).update(assignment_type: at[:label])
        end
        alter_table(:timeslot_contents) do
            drop_foreign_key :assignment_type_id
            # set_column_not_null :assignment_type
        end
        drop_table(:assignment_types)

        # import_types
        alter_table(:imports) do
            add_column :type, String
        end
        DB[:import_types].all.each do |at|
            DB[:imports].where(import_type_id: at[:id]).update(type: at[:label])
        end
        alter_table(:imports) do
            drop_foreign_key :import_type_id
            set_column_not_null :type
        end
        drop_table(:import_types)

        # resource_types
        alter_table(:resources) do
            add_column :type, String
        end
        DB[:resource_types].all.each do |at|
            DB[:resources].where(resource_type_id: at[:id]).update(type: at[:label])
        end
        alter_table(:resources) do
            drop_foreign_key :resource_type_id
            set_column_not_null :type
        end
        drop_table(:resource_types)

        # timeslot_content_types
        alter_table(:timeslot_contents) do
            add_column :type, String
        end
        DB[:timeslot_content_types].all.each do |at|
            DB[:timeslot_contents].where(timeslot_content_type_id: at[:id]).update(type: at[:label])
        end
        alter_table(:timeslot_contents) do
            drop_foreign_key :timeslot_content_type_id
            set_column_not_null:type
        end
        drop_table(:timeslot_content_types)
    end
end
