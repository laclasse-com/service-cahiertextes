# frozen_string_literal: true

class Note < Sequel::Model( :notes )
    many_to_many :attachments, join_table: :notes_attachments
    many_to_one :timeslot
    many_to_one :users, key: :author_id
end

class NoteAttachment < Sequel::Model( :notes_attachments )
end
