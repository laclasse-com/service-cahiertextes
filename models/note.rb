# frozen_string_literal: true

class Note < Sequel::Model( :notes )
    many_to_many :attachments, join_table: :notes_attachments
    many_to_one :timeslot
    many_to_one :author, key: :author_id, class: :User
end

class NoteAttachment < Sequel::Model( :notes_attachments )
end
