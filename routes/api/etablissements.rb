# -*- coding: utf-8 -*-

module CahierDeTextesApp
  module Routes
    module Api
      module Etablissements
        def self.registered( app )
          app.get '/api/etablissements/:uai/?' do
            # TODO: check if exists in annuaire
            etablissement = DataManagement::Accessors.create_or_get( Etablissement,
                                                                     UAI: params['uai'] )

            hetablissement = etablissement.to_hash
            hetablissement[:nb_creneaux] = CreneauEmploiDuTemps.where( etablissement_id: etablissement.id )
                                                               .where( Sequel.lit( "DATE_FORMAT( date_creation, '%Y-%m-%d') >= '#{CahierDeTextesApp::Utils.date_rentree}'" ) )
                                                               .count
            hetablissement[:imports] = etablissement.imports.map(&:to_hash)
            hetablissement[:matchables] = etablissement.matchables.map(&:to_hash)

            json( hetablissement )
          end

          app.post '/api/etablissements/:uai/?' do
            etablissement = DataManagement::Accessors.create_or_get( Etablissement,
                                                                     UAI: params['uai'] )

            etablissement.debut_annee_scolaire = params['debut_annee_scolaire'] if params.key?( 'debut_annee_scolaire' )
            etablissement.fin_annee_scolaire = params['fin_annee_scolaire'] if params.key?( 'fin_annee_scolaire' )
            etablissement.date_premier_jour_premiere_semaine = params['date_premier_jour_premiere_semaine'] if params.key?( 'date_premier_jour_premiere_semaine' )
            etablissement.save

            json etablissement.to_hash
          end

          app.get '/api/etablissements/:uai/statistiques/regroupements/?' do
            etablissement = Etablissement[ uai: params['uai'] ]

            halt( 404, "Établissement #{params['uai']} inconnu" ) if etablissement.nil?

            json etablissement.statistiques_regroupements
          end

          app.get '/api/etablissements/:uai/statistiques/regroupements/:regroupement_id/?' do
            cahier_de_textes = CahierDeTextes[ regroupement_id: params['regroupement_id'] ]

            halt( 404, "Classe #{params['regroupement_id']} inconnue dans l'établissement #{params['uai']}" ) if cahier_de_textes.nil?

            json cahier_de_textes.statistiques.to_hash
          end

          app.get '/api/etablissements/:uai/statistiques/enseignants/?' do
            etablissement = Etablissement[ uai: params['uai'] ]

            halt( 404, "Établissement #{params['uai']} inconnu" ) if etablissement.nil?

            json etablissement.statistiques_enseignants
          end

          app.get '/api/etablissements/:uai/statistiques/enseignants/:enseignant_id/?' do
            etablissement = Etablissement[ uai: params['uai'] ]

            halt( 404, "Établissement #{params['uai']} inconnu" ) if etablissement.nil?

            saisies = etablissement.saisies_enseignant( params['enseignant_id'] )
            saisies[:saisies] = saisies[:saisies].map do |saisie|
              saisie[:cours] = saisie[:cours].to_hash
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
