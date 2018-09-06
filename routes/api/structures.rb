# coding: utf-8
module CahierDeTextesApp
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
                                                .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                                                .count
            hstructure[:imports] = structure.imports.map(&:to_hash)
            hstructure[:matchables] = structure.matchables.map(&:to_hash)

            json( hstructure )
          end

          app.post '/api/structures/:uai/?' do
            structure = DataManagement::Accessors.create_or_get( Structure,
                                                                     UAI: params['uai'] )

            structure.debut_annee_scolaire = params['debut_annee_scolaire'] if params.key?( 'debut_annee_scolaire' )
            structure.fin_annee_scolaire = params['fin_annee_scolaire'] if params.key?( 'fin_annee_scolaire' )
            structure.date_premier_jour_premiere_semaine = params['date_premier_jour_premiere_semaine'] if params.key?( 'date_premier_jour_premiere_semaine' )
            structure.save

            json structure.to_hash
          end

          app.get '/api/structures/:uai/statistiques/regroupements/?' do
            structure = Structure[ uai: params['uai'] ]

            halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

            json structure.statistiques_regroupements
          end

          app.get '/api/structures/:uai/statistiques/regroupements/:regroupement_id/?' do
            cahier_de_textes = CahierDeTextes[ regroupement_id: params['regroupement_id'] ]

            halt( 404, "Classe #{params['regroupement_id']} inconnue dans l'établissement #{params['uai']}" ) if cahier_de_textes.nil?

            json cahier_de_textes.statistiques.to_hash
          end

          app.get '/api/structures/:uai/statistiques/enseignants/?' do
            structure = Structure[ uai: params['uai'] ]

            halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

            json structure.statistiques_enseignants
          end

          app.get '/api/structures/:uai/statistiques/enseignants/:enseignant_id/?' do
            structure = Structure[ uai: params['uai'] ]

            halt( 404, "Établissement #{params['uai']} inconnu" ) if structure.nil?

            saisies = structure.saisies_enseignant( params['enseignant_id'] )
            saisies[:saisies] = saisies[:saisies].map do |saisie|
              saisie[:sessions] = saisie[:sessions].to_hash
              saisie[:devoirs] = saisie[:devoirs].map(&:to_hash)

              saisie
            end

            json( saisies )
          end
        end
      end
    end
  end
end
