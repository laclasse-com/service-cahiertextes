# coding: utf-8

module Routes
    module Api
        module Structures
            def self.registered( app )
                app.get '/api/structures/:uai/?' do
                    # {
                    param :uai, String, required: true
                    # }

                    # TODO: check if exists in annuaire
                    structure = DataManagement::Accessors.create_or_get( Structure,
                                                                         UAI: params['uai'] )

                    hstructure = structure.to_hash
                    hstructure[:nb_timeslots] = Timeslot.where( structure_id: structure.id )
                                                        .where( Sequel.lit( "DATE_FORMAT( ctime, '%Y-%m-%d') >= '#{Utils.date_rentree}'" ) )
                                                        .count
                    hstructure[:imports] = structure.imports.map(&:to_hash)
                    hstructure[:matchables] = structure.matchables.map(&:to_hash)

                    json( hstructure )
                end

                app.post '/api/structures/:uai/?' do
                    # {
                    param :uai, String, required: true
                    param :schoolyear_start, Date, required: true
                    param :schoolyear_end, Date, required: true
                    param :first_day_of_first_week, Date, required: true
                    # }

                    structure = DataManagement::Accessors.create_or_get( Structure,
                                                                         UAI: params['uai'] )

                    structure.schoolyear_start = params['schoolyear_start'] if params.key?( 'schoolyear_start' )
                    structure.schoolyear_end = params['schoolyear_end'] if params.key?( 'schoolyear_end' )
                    structure.first_day_of_first_week = params['first_day_of_first_week'] if params.key?( 'first_day_of_first_week' )
                    structure.save

                    json structure.to_hash
                end

                app.get '/api/structures/:uai/statistics/groups/?' do
                    # {
                    param :uai, String, required: true
                    # }

                    structure = Structure[ uai: params['uai'] ]

                    halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

                    json structure.statistics_regroupements
                end

                app.get '/api/structures/:uai/statistics/groups/:group_id/?' do
                    # {
                    param :uai, String, required: true
                    param :group_id, Integer, required: true
                    # }

                    cahier_de_textes = CahierDeTextes[ regroupement_id: params['group_id'] ]

                    halt( 404, "Classe #{params['group_id']} inconnue dans l'établissement #{params['uai']}" ) if cahier_de_textes.nil?

                    json cahier_de_textes.statistics.to_hash
                end

                app.get '/api/structures/:uai/statistics/teachers/?' do
                    # {
                    param :uai, String, required: true
                    # }

                    structure = Structure[ uai: params['uai'] ]

                    halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

                    json structure.statistics_enseignants
                end

                app.get '/api/structures/:uai/statistics/teachers/:teacher_id/?' do
                    # {
                    param :uai, String, required: true
                    param :teacher_id, String, required: true
                    # }

                    structure = Structure[ uai: params['uai'] ]

                    halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

                    sessions = structure.sessions_author( params['teacher_id'] )
                    sessions[:sessions] = sessions[:sessions].map do |session|
                        session[:sessions] = session[:sessions].to_hash
                        session[:assignments] = session[:assignments].map(&:to_hash)

                        session
                    end

                    json( sessions )
                end
            end
        end
    end
end
