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
      params {
        requires :id, desc: 'id de la matière'
      }
      get '/matieres/:id' do
        AnnuaireWrapper::Matiere.get( params[:id] )
      end

      desc 'retourne la liste des enseignants de l\'établissement'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
      }
      get 'etablissements/:uai/enseignants' do
        AnnuaireWrapper::Etablissement.get_enseignants( params[:uai] )
      end

      desc 'retourne la liste des regroupements de l\'établissement'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
      }
      get 'etablissements/:uai/regroupements' do
        AnnuaireWrapper::Etablissement.get_regroupements( params[:uai] )
      end

      desc 'Renvoi le détail d\'un regroupement'
      params {
        requires :id, desc: 'id du regroupement'
      }
      get '/regroupements/:id' do
        AnnuaireWrapper::Regroupement.get( params[:id] )
      end

      desc 'Renvoi le détail d\'un utilisateur'
      params {
        requires :id, desc: 'id de l\'utilisateur'
      }
      get '/users/:id' do
        AnnuaireWrapper::User.get( params[:id] )
      end
    end
  end
end
