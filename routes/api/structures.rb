# coding: utf-8

module Routes
    module Api
        module Structures
            def self.registered( app )
                app.get '/api/structures/:uai/?' do
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
                    structure = DataManagement::Accessors.create_or_get( Structure,
                                                                         UAI: params['uai'] )

                    structure.schoolyear_start = params['schoolyear_start'] if params.key?( 'debut_annee_scolaire' )
                    structure.schoolyear_end = params['schoolyear_end'] if params.key?( 'schoolyear_end' )
                    structure.first_day_of_first_week = params['first_day_of_first_week'] if params.key?( 'first_day_of_first_week' )
                    structure.save

                    json structure.to_hash
                end

                app.get '/api/structures/:uai/statistics/groups/?' do
                    structure = Structure[ uai: params['uai'] ]

                    halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

                    json structure.statistics_regroupements
                end

                app.get '/api/structures/:uai/statistics/groups/:group_id/?' do
                    cahier_de_textes = CahierDeTextes[ regroupement_id: params['group_id'] ]

                    halt( 404, "Classe #{params['group_id']} inconnue dans l'établissement #{params['uai']}" ) if cahier_de_textes.nil?

                    json cahier_de_textes.statistics.to_hash
                end

                app.get '/api/structures/:uai/statistics/enseignants/?' do
                    structure = Structure[ uai: params['uai'] ]

                    halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

                    json structure.statistics_enseignants
                end

                app.get '/api/structures/:uai/statistics/enseignants/:enseignant_id/?' do
                    structure = Structure[ uai: params['uai'] ]

                    halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

                    saisies = structure.saisies_enseignant( params['enseignant_id'] )
                    saisies[:saisies] = saisies[:saisies].map do |saisie|
                        saisie[:sessions] = saisie[:sessions].to_hash
                        saisie[:assignments] = saisie[:assignments].map(&:to_hash)

                        saisie
                    end

                    json( saisies )
                end
            end
        end
    end
end
