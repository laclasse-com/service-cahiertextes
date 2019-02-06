# frozen_string_literal: true

class User < Sequel::Model( :users )
    one_to_many :notes, key: :author_id
    one_to_many :sessions, key: :author_id
    one_to_many :assignments, key: :author_id
    one_to_many :assignment_done_markers, key: :author_id
    one_to_many :imports, key: :author_id
    many_to_one :author, key: :author_id, class: :User
    many_to_many :timeslots, join_table: :timeslots_users, class: :Timeslot, left_key: :user_id, right_key: :timeslots_id
end
