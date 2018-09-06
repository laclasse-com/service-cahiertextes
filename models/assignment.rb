class Assignment < Sequel::Model( :assignments )
    many_to_many :resources
    many_to_one :timeslot
    many_to_one :assignment_type
    one_to_many :assignment_done_markers
    many_to_one :sessions

    def to_deep_hash
        hash = to_hash

        hash[:resources] = resources.map(&:to_hash)

        hash
    end

    def done_by!( eleve_id )
        add_assignment_done_marker( eleve_id: eleve_id, date_fait: Time.now )
    end

    def done_by?( eleve_id )
        assignment_done_markers_dataset.where(eleve_id: eleve_id).count > 0
    end

    def done_on_the( eleve_id )
        assignment_done_markers_dataset.where(eleve_id: eleve_id).first[:date_fait]
    end

    def to_do_by!( eleve_id )
        assignment_done_markers_dataset.where(eleve_id: eleve_id).destroy
    end

    def toggle_deleted
        update( deleted: !deleted, date_modification: Time.now )
        save
    end

    def toggle_fait( user )
        done_by?( user['id'] ) ? a_faire_par!( user['id'] ) : done_by!( user['id'] )
    end

    def copie( session_id, timeslot_id, date_due )
        new_assignment = Assignment.create( session_id: session_id,
                                            assignment_type_id: assignment_type_id,
                                            timeslot_id: timeslot_id,
                                            content: content,
                                            date_due: date_due,
                                            time_estimate: time_estimate,
                                            author_id: author_id,
                                            ctime: Time.now )

        resources.each do |resource|
            new_assignment.add_resource( resource )
        end
    end

    def modifie( params )
        self.date_due = params['date_due']
        self.timeslot_id = params['timeslot_id']
        self.assignment_type_id = params['assignment_type_id']
        self.content = params['content']
        self.time_estimate = params['time_estimate'] unless params['time_estimate'].nil?
        self.session_id = params['session_id'] unless params['session_id'].nil?
        self.author_id = params['author_id'] unless params['author_id'].nil?

        if params['resources']
            remove_all_resources

            params['resources'].each do |resource|
                add_resource( DataManagement::Accessors.create_or_get( Resource, name: resource['name'],
                                                                       hash: resource['hash'] ) )
            end
        end

        self.date_modification = Time.now

        save
    end
end

class AssignmentType < Sequel::Model( :assignment_types )
    one_to_many :assignments
end

class AssignmentResource < Sequel::Model( :assignments_resources )
end

class AssignmentDoneMarker < Sequel::Model( :assignment_done_markers )
    many_to_one :assignment
end
