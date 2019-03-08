# frozen_string_literal: true

Sequel.migration do
    change do
        puts '050_user_id_links_to_users_table.rb'

        [:notes, :sessions, :assignments, :assignment_done_markers, :imports].each do |table|
            nullable_author_id = table == :imports

            alter_table( table ) do
                rename_column :author_id, :old_author_id
                add_foreign_key :author_id, :users, null: true
            end

            DB[ table ].select( :old_author_id ).all.uniq.map { |u| u[:old_author_id] }.compact.each do |uid|
                user_id = DB[:users].where( uid: uid ).select( :id ).first
                if user_id.nil?
                    DB[ table ].where( old_author_id: uid ).delete unless nullable_author_id
                else
                    unless user_id.nil?
                        DB[ table ].where( old_author_id: uid )
                                   .update( author_id: user_id[:id] )
                    end
                end
            end

            alter_table( table ) do
                drop_column :old_author_id
                set_column_not_null :author_id unless nullable_author_id
            end
        end
    end
end
