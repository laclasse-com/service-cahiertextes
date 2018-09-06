class Resource < Sequel::Model( :resources )
  many_to_many :sessions, join_table: :sessions_resources
  many_to_many :devoirs, join_table: :devoirs_resources
end
