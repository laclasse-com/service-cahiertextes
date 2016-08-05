# coding: utf-8

Sequel.migration do
  change do
    alter_table( :imports ) do
      add_column :comment, String, null: true
    end
  end
end
