# coding: utf-8

Sequel.migration do
  change do
    alter_table( :imports ) do
      add_column :comment, String, null: true
    end
  end
end
puts 'applying 012_add_comment_to_imports.rb'
