# frozen_string_literal: true

Sequel.migration do
    change do
        alter_table( :imports ) do
            drop_column :stage
        end
    end
end
puts '035_drop_imports_stage.rb'
