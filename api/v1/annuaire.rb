# -*- coding: utf-8 -*-

require_relative '../../lib/annuaire_wrapper'

module CahierDeTextesAPI
  module V1
    # API d'interfaçage avec l'annuaire
    class AnnuaireAPI < Grape::API
      format :json

      desc 'Renvoi la liste de toutes les matières'
      get '/matieres' do
        AnnuaireWrapper::Matiere.query
      end

      desc 'Renvoi le détail d\'une matière'
      params do
        requires :id, desc: 'id de la matière'
      end
      get '/matieres/:id' do
        AnnuaireWrapper::Matiere.get( params[:id] )
      end

      desc 'retourne un établissement'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'
      end
      get '/etablissements/:uai' do
        AnnuaireWrapper::Etablissement.get( params[:uai], 2 )
      end

      desc 'retourne la liste des enseignants de l\'établissement'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'
      end
      get '/etablissements/:uai/enseignants' do
        AnnuaireWrapper::Etablissement.get_enseignants( params[:uai] )
      end

      desc 'retourne la liste des regroupements de l\'établissement'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'
      end
      get '/etablissements/:uai/regroupements' do
        regroupements = AnnuaireWrapper::Etablissement.get_regroupements( params[:uai] )

        regroupements.keys.each do |type|
          regroupements[ type ].each do |regroupement|
            regroupement[ 'libelle' ] ||= regroupement[ 'libelle_aaf' ]
          end
        end

        regroupements
      end

      desc 'Renvoi le détail d\'un regroupement'
      params do
        requires :id, desc: 'id du regroupement'
      end
      get '/regroupements/:id' do
        AnnuaireWrapper::Regroupement.get( params[:id] )
      end

      desc 'Renvoi le détail d\'un utilisateur'
      params do
        requires :id, desc: 'id de l\'utilisateur'
      end
      get '/users/:id' do
        AnnuaireWrapper::User.get( params[:id] )
      end
    end
  end
end
