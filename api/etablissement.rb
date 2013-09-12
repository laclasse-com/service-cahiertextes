# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EtablissementAPI < Grape::API
    format :json

    desc 'statistiques des cahiers de textes par classes/mois/matières'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
    }
    get '/:uai/classe' do
      Etablissement.where(uai: params[:uai]).first.statistiques_classes
    end

    desc 'statistiques du cahier de textes d\'une classe'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :classe_id, desc: 'identifiant annuaire de la classe'
    }
    get '/:uai/classe/:classe_id' do
      cahier_de_textes = CahierDeTextes[ regroupement_id: params[:classe_id] ]

      error!( 'Classe inconnue', 404 ) if cahier_de_textes.nil?

      cahier_de_textes.statistiques
    end

    desc 'valide toutes les saisies non validées de la classe'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :classe_id, desc: 'identifiant annuaire de la classe'
    }
    put '/:uai/classe/:classe_id' do
      cahier_de_textes = CahierDeTextes[ regroupement_id: params[:classe_id] ]

      error!( 'Classe inconnue', 404 ) if cahier_de_textes.nil?

      cahier_de_textes.valide!
    end

    desc 'statistiques des cahiers de textes par enseignants/mois'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
    }
    get '/:uai/enseignant' do
      Etablissement.where(uai: params[:uai]).first.statistiques_enseignants
    end

    desc 'saisies détaillées d\'un enseignant dans les cahiers de textes par mois/classes'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :enseignant_id, desc: 'identifiant annuaire de l\'enseignant'
    }
    get '/:uai/enseignant/:enseignant_id' do
      Etablissement.where(uai: params[:uai]).first.saisies_enseignant( params[:enseignant_id] )
    end

    desc 'valide toutes les saisies non validées de l\'enseignant'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :enseignant_id
      optional :debut, type: Time
      optional :fin, type: Time
    }
    put '/:uai/enseignant/:enseignant_id' do
      Etablissement.where(uai: params[:uai]).first.valide_enseignant!( params[:enseignant_id] )
    end

  end
end
