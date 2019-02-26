# frozen_string_literal: true

class Session < Sequel::Model( :sessions )
    many_to_many :attachments, join_table: :sessions_attachments
    many_to_one :timeslot
    one_to_many :assignments
    many_to_one :author, key: :author_id, class: :User
    many_to_many :targets, join_table: :sessions_users, class: :User, left_key: :session_id, right_key: :user_id
    many_to_one :t

    def to_deep_hash
        hash = to_hash

        hash[:attachments] = attachments.map(&:to_hash)
        hash[:assignments] = assignments.select { |assignment| assignment.dtime.nil? || assignment.dtime > UNDELETE_TIME_WINDOW.minutes.ago }
        hash[:assignments].each do |assignment|
            assignment[:attachments] = assignment.attachments.map(&:to_hash)
        end
        hash[:assignments] = hash[:assignments].map(&:to_hash)

        hash
    end

    def modify( params )
        self.mtime = Time.now

        self.stime = params['stime'] if params.key?( 'stime' )
        self.content = params['content'] if params.key?( 'content' )
        self.date = params['date'] if params.key?( 'date' )

        if params['attachments']
            remove_all_attachments
            params['attachments'].each do |attachment|
                add_attachment( DataManagement::Accessors.create_or_get( Attachment,
                                                                         name: attachment['name'],
                                                                         hash: attachment['hash'] ) )
            end
        end

        save
    end
end

class SessionAttachment < Sequel::Model( :sessions_attachments )
end
