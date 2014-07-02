# coding: utf-8

Sequel.migration do
  change do
    add_column :devoirs, :deleted, TrueClass, default: false
  end
end
