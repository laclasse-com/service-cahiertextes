# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class EtablissementsAPI < Grape::API
      format :json

      before  do
        user_needs_to_be( %w( DIR ENS ), false )
      end

      desc 'statistiques des cahiers de textes par classes/mois/matières'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
      }
      get '/:uai/statistiques/classes' do
        etablissement = Etablissement.where(uai: params[:uai]).first

        etablissement.statistiques_classes unless etablissement.nil?

        error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?
      end

      desc 'statistiques du cahier de textes d\'une classe'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
        requires :regroupement_id, desc: 'identifiant annuaire de la classe'
      }
      get '/:uai/statistiques/classes/:regroupement_id' do
        cahier_de_textes = CahierDeTextes[ regroupement_id: params[:regroupement_id] ]

        error!( "Classe #{params[:regroupement_id]} inconnue dans l'établissement #{params[:uai]}", 404 ) if cahier_de_textes.nil?

        cahier_de_textes.statistiques unless cahier_de_textes.nil?
      end

      desc 'statistiques des cahiers de textes par enseignants/mois'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
      }
      get '/:uai/statistiques/enseignants' do
        etablissement = Etablissement.where(UAI: params[:uai]).first

        error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

        etablissement.statistiques_enseignants unless etablissement.nil?
      end

      desc 'saisies détaillées d\'un enseignant dans les cahiers de textes par mois/classes'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
        requires :enseignant_id, desc: 'identifiant annuaire de l\'enseignant'
      }
      get '/:uai/statistiques/enseignants/:enseignant_id' do
        etablissement = Etablissement.where(uai: params[:uai]).first

        error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

        etablissement.saisies_enseignant( params[:enseignant_id] ) unless etablissement.nil?
      end
    end
  end
end
