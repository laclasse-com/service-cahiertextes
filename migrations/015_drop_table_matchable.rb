# coding: utf-8

Sequel.migration do
  change do
    drop_table(:matchable)
  end
end
