# frozen_string_literal: true

class Assignment < Sequel::Model( :assignments )
    many_to_one :timeslot
    many_to_one :session
    many_to_one :assignment_type
    many_to_one :author, key: :author_id, class: :User
    many_to_many :attachments
    many_to_many :targets, join_table: :assignments_users, class: :User, left_key: :assignment_id, right_key: :user_id
    one_to_many :assignment_done_markers
    many_to_one :trail

    def to_deep_hash
        hash = to_hash

        hash[:attachments] = attachments.map(&:to_hash)

        hash
    end

    def done_by!( author_id )
        add_assignment_done_marker( author_id: author_id, rtime: Time.now )
    end

    def done_by?( author_id )
        assignment_done_markers_dataset.where(author_id: author_id).count.positive?
    end

    def done_on_the( author_id )
        assignment_done_markers_dataset.where(author_id: author_id).first[:rtime]
    end

    def to_be_done_by!( author_id )
        assignment_done_markers_dataset.where(author_id: author_id).destroy
    end

    def modify( params )
        self.date = params['date'] if params.key?( 'date' )
        self.timeslot_id = params['timeslot_id'] if params.key?( 'timeslot_id' )
        self.assignment_type_id = params['assignment_type_id'] if params.key?( 'assignment_type_id' )
        self.content = params['content'] if params.key?( 'content' )
        self.load = params['load'] if params.key?( 'load' )
        self.difficulty = params['difficulty'] if params.key?( 'difficulty' )
        self.session_id = params['session_id'] if params.key?( 'session_id' )
        self.author_id = params['author_id'] if params.key?( 'author_id' )

        if params['attachments']
            remove_all_attachments

            params['attachments'].each do |attachment|
                add_attachment( DataManagement::Accessors.create_or_get( Attachment,
                                                                         name: attachment['name'],
                                                                         hash: attachment['hash'] ) )
            end
        end

        self.mtime = Time.now

        save
    end
end

class AssignmentType < Sequel::Model( :assignment_types )
    one_to_many :assignments
end

class AssignmentAttachment < Sequel::Model( :assignments_attachments )
end

class AssignmentDoneMarker < Sequel::Model( :assignment_done_markers )
    many_to_one :assignment
    many_to_one :author, key: :author_id, class: :User
end
