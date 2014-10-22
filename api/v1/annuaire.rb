# -*- coding: utf-8 -*-

require_relative '../../lib/annuaire'

module CahierDeTextesAPI
  module V1
    # API d'interfaçage avec l'annuaire
    class AnnuaireAPI < Grape::API
      format :json

      desc 'Renvoi la liste de toutes les matières'
      get '/matieres' do
        Annuaire.get_matieres
      end

      desc 'Renvoi le détail d\'une matière'
      params {
        requires :id, desc: 'id de la matière'
      }
      get '/matieres/:id' do
        Annuaire.get_matiere( params[:id] )
      end

      desc 'retourne la liste des enseignants de l\'établissement'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
      }
      get 'etablissements/:uai/enseignants' do
        Annuaire.get_etablissement_enseignants( params[:uai] )
      end

      desc 'retourne la liste des regroupements de l\'établissement'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
      }
      get 'etablissements/:uai/regroupements' do
        Annuaire.get_etablissement_regroupements( params[:uai] )
      end

      desc 'Renvoi le détail d\'un regroupement'
      params {
        requires :id, desc: 'id du regroupement'
      }
      get '/regroupements/:id' do
        regroupement = Annuaire.get_regroupement( params[:id] )
        cahier_de_textes = CahierDeTextes.where( regroupement_id: params[:id] ).first

        # création du cahier de textes au cas où il n'existe pas déjà
        cahier_de_textes = CahierDeTextes.create( date_creation: Time.now,
                                                  regroupement_id: params[:id] ) if cahier_de_textes.nil?

        regroupement[:cahier_de_textes_id] = cahier_de_textes[:id]

        regroupement
      end

      desc 'Renvoi le détail d\'un utilisateur'
      params {
        requires :id, desc: 'id de l\'utilisateur'
      }
      get '/users/:id' do
        Annuaire.get_user( params[:id] )
      end
    end
  end
end
