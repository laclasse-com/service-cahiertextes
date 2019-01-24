# frozen_string_literal: true

class Users < Sequel::Model( :users )
    one_to_many :notes, key: :author_id
    one_to_many :sessions, key: :author_id
    one_to_many :assignments, key: :author_id
    one_to_many :assignment_done_markers, key: :author_id
    one_to_many :imports, key: :author_id
end
