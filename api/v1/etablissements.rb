# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class EtablissementsAPI < Grape::API
      format :json

      before  do
        error!( '401 Unauthorized', 401 ) unless user.is?( 'DIR' ) || user.is?( 'ENS' )
      end

      desc 'statistiques des cahiers de textes par classes/mois/matières'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
      }
      get '/:uai/statistiques/classes' do
        Etablissement.where(uai: params[:uai]).first.statistiques_classes
      end

      desc 'statistiques du cahier de textes d\'une classe'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
        requires :regroupement_id, desc: 'identifiant annuaire de la classe'
      }
      get '/:uai/statistiques/classes/:regroupement_id' do
        cahier_de_textes = CahierDeTextes[ regroupement_id: params[:regroupement_id] ]

        error!( 'Classe inconnue', 404 ) if cahier_de_textes.nil?

        cahier_de_textes.statistiques
      end

      desc 'statistiques des cahiers de textes par enseignants/mois'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
      }
      get '/:uai/statistiques/enseignants' do
        Etablissement.where(UAI: params[:uai]).first.statistiques_enseignants
      end

      desc 'saisies détaillées d\'un enseignant dans les cahiers de textes par mois/classes'
      params {
        requires :uai, desc: 'Code UAI de l\'établissement'
        requires :enseignant_id, desc: 'identifiant annuaire de l\'enseignant'
      }
      get '/:uai/statistiques/enseignants/:enseignant_id' do
        Etablissement.where(uai: params[:uai]).first.saisies_enseignant( params[:enseignant_id] )
      end
    end
  end
end
