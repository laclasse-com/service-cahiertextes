# frozen_string_literal: true

Sequel.migration do
    change do
        puts '043_add_table_attachment_types.rb'

        create_table!(:attachment_types) do
            primary_key :id

            String :label, null: false
            String :description
        end
        [['DOC', 'Document ENT']].each do |attachment_type|
            self[:attachment_types].insert( %i[label description], attachment_type )
        end

        alter_table( :attachments ) do
            add_foreign_key :attachment_type_id, :attachment_types, null: true
        end
        DB[:attachments].update(attachment_type_id: DB[:attachment_types].all.first[:id])

        alter_table( :attachments ) do
            set_column_not_null :attachment_type_id
        end
    end
end
