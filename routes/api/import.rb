# frozen_string_literal: true

require_relative '../../lib/pronote'
require_relative '../../lib/xml_to_hash'
require_relative '../../models/import'

module Routes
    module Api
        module ImportAPI
            def self.registered( app )
                app.post '/api/import/log/start/?' do
                    # {
                    param 'author_id', Integer, required: true
                    param 'structure_id', String, required: true
                    param 'type', String, required: true
                    # }

                    user_id = get_ctxt_user( user['id'] ).id

                    halt( 401 ) unless user_is_x_in_structure_s?( %w[ADM], params['structure_id'] )
                    halt( 401 ) unless user_id == params['author_id']

                    json( Import.create( structure_id: params['structure_id'],
                                         ctime: DateTime.now,
                                         type: params['type'],
                                         author_id: user_id ) )
                end

                app.post '/api/import/pronote/decrypt/?' do
                    # {
                    #  'file', required: true
                    # }

                    json( File.open( params['file']['tempfile'] ) do |xml|
                              nxml = Nokogiri::XML( xml )

                              uai = nxml.search( 'UAI' ).children.text

                              halt( 409 ) unless Utils.validate_uai( uai )
                              halt( 401 ) unless user_is_x_in_structure_s?( %w[ADM], uai )

                              crypted = !nxml.search( 'CLES' ).empty?

                              if crypted
                                  uai = nxml.search( 'UAI' ).children.text

                                  halt( 401 ) unless user_is_profile_in_structure?( 'ADM', uai )

                                  hash = Hash.from_xml( ProNote.decrypt_xml( File.open( params['file']['tempfile'] ) ) )[:ExportEmploiDuTemps]
                              else
                                  hash = Hash.from_xml( File.open( params['file']['tempfile'] ) )[:ExportEmploiDuTemps]
                              end

                              slot_length_minutes = hash[:GrilleHoraire].first[:DureePlace].to_i
                              slots_list = hash[:GrilleHoraire].first[:PlacesParJour].first[:Place]

                              {
                                  structure_id: hash[:UAI],
                                  subjects: hash[:Matieres].first[:Matiere].map do |subject|
                                      {
                                          id: subject[:Ident].to_i,
                                          name: subject[:Libelle]
                                      }
                                  end,
                                  rooms: hash[:Salles].first[:Salle].map do |room|
                                      {
                                          id: room[:Ident].to_i,
                                          name: room[:Nom]
                                      }
                                  end,
                                  classes: hash[:Classes].first[:Classe].map do |group|
                                      {
                                          id: group[:Ident].to_i,
                                          name: group[:Nom],
                                          parts_ids: !group.key?(:PartieDeClasse) ? [] : group[:PartieDeClasse].map { |pdc| pdc[:Ident].to_i }
                                      }
                                  end,
                                  groupes: hash[:Groupes].first[:Groupe].map do |group|
                                      {
                                          id: group[:Ident].to_i,
                                          name: group[:Nom],
                                          parts_ids: group[:PartieDeClasse].map { |pdc| pdc[:Ident].to_i }
                                      }
                                  end,
                                  timeslots: hash[:Cours].first[:Cours].map do |timeslot|
                                      start_time = slots_list[ timeslot[:NumeroPlaceDebut].to_i ][:LibelleHeureDebut]
                                      end_time = (Time.parse(start_time) + timeslot[:NombrePlaces].to_i * slot_length_minutes.minutes).iso8601.split('T')[1].split('+').first
                                      groups = %w[Classe Groupe].map do |group_type|
                                          !timeslot.key?( group_type.to_sym ) ? [] : timeslot[ group_type.to_sym ].map do |group| # rubocop:disable Style/MultilineTernaryOperator
                                              {
                                                  type: group_type,
                                                  id: group[:Ident].to_i,
                                                  active_weeks: group[:Semaines].to_i
                                              }
                                          end
                                      end
                                                                .compact
                                                                .flatten

                                      {
                                          yearly: timeslot[:Annuel] == "1",
                                          weekday: timeslot[:Jour].to_i,
                                          start_time: start_time,
                                          end_time: end_time,
                                          subjects_ids: !timeslot.key?(:Matiere) ? -1 : timeslot[:Matiere].map { |subject| subject[:Ident].to_i },
                                          groups: groups,
                                          rooms: !timeslot.key?(:Salle) ? [] : timeslot[:Salle].map do |room| # rubocop:disable Style/MultilineTernaryOperator
                                              {
                                                  id: room[:Ident].to_i,
                                                  active_weeks: room[:Semaines].to_i
                                              }
                                          end
                                          # ,
                                          # cancelled_weeks: !timeslot.key?(:SemainesAnnulation) ? -1 : timeslot[:SemainesAnnulation].to_i
                                      }
                                  end
                              }
                          end )
                end
            end
        end
    end
end
