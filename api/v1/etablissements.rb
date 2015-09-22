# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class EtablissementsAPI < Grape::API
      format :json

      before  do
        user_needs_to_be( %w( DIR ENS ), false )
      end

      desc 'statistiques des cahiers de textes par classes/mois/matières'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'
      end
      get '/:uai/statistiques/classes' do
        etablissement = Etablissement.where(uai: params[:uai]).first

        error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

        etablissement.statistiques_classes
      end

      desc 'statistiques du cahier de textes d\'une classe'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'
        requires :regroupement_id, desc: 'identifiant annuaire de la classe'
      end
      get '/:uai/statistiques/classes/:regroupement_id' do
        cahier_de_textes = CahierDeTextes[ regroupement_id: params[:regroupement_id] ]

        error!( "Classe #{params[:regroupement_id]} inconnue dans l'établissement #{params[:uai]}", 404 ) if cahier_de_textes.nil?

        cahier_de_textes.statistiques
      end

      desc 'statistiques des cahiers de textes par enseignants/mois'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'

        optional :detailed, desc: 'include full details of each Enseignant for graphs'
      end
      get '/:uai/statistiques/enseignants' do
        detailed = params.key?(:detailed) ? params[:detailed] == 'true' : false
        etablissement = Etablissement.where(UAI: params[:uai]).first

        error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

        etablissement.statistiques_enseignants( detailed )
      end

      desc 'saisies détaillées d\'un enseignant dans les cahiers de textes par mois/classes'
      params do
        requires :uai, desc: 'Code UAI de l\'établissement'
        requires :enseignant_id, desc: 'identifiant annuaire de l\'enseignant'
      end
      get '/:uai/statistiques/enseignants/:enseignant_id' do
        etablissement = Etablissement.where(uai: params[:uai]).first

        error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

        etablissement.saisies_enseignant( params[:enseignant_id] )
      end
    end
  end
end
