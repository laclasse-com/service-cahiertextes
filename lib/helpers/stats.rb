# frozen_string_literal: true

require 'net/http'

require 'yaml'

module LaClasse
    module Helpers
        module Stats
            def group_stats( group_id )
                timeslots = Timeslot.where(group_id: group_id).all

                { timeslots: { empty: timeslots.select { |timeslot| timeslot.sessions.empty? && timeslot.assignments.empty? }.map( &:id ),
                               filled: timeslots.select { |creneau| !timeslot.sessions.empty? || !timeslot.assignments.empty? }.map( &:id ) } }
            end

            def teacher_stats( teacher_id, validated = nil, from = nil, to = nil, subjects_ids = nil, groups_ids = nil )
                def request( model )
                    req = model.where( author_id: teacher_id )
                    req = req.where( :date > from ) unless from.nil?
                    req = req.where( :date < to ) unless to.nil?

                    unless validated.nil?
                        if validated
                            req = req.where( vtime: nil )
                        else
                            req = req.where( Sequel.~( vtime: nil ) )
                        end
                    end

                    unless groups_ids.nil? && subjects_ids.nil?
                        ts_req = Timeslot.select(:id)
                        ts_req = ts_req.where(group_id: groups_ids) unless groups_ids.nil?
                        ts_req = ts_req.where(subject_id: subjects_ids) unless subjects_ids.nil?

                        req = req.where(timeslot_id: ts_req)
                    end

                    req
                end

                { sessions: request( Session ).naked.all,
                  assignments: request( Assignment ).naked.all }
            end
        end
    end
end
