# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EtablissementsAPI < Grape::API
    format :json

    desc 'statistiques des cahiers de textes par classes/mois/matières'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
    }
    get '/:uai/classes' do
      Etablissement.where(uai: params[:uai]).first.statistiques_classes
    end

    desc 'statistiques du cahier de textes d\'une classe'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :classe_id, desc: 'identifiant annuaire de la classe'
    }
    get '/:uai/classes/:classe_id' do
      cahier_de_textes = CahierDeTextes[ regroupement_id: params[:classe_id] ]

      error!( 'Classe inconnue', 404 ) if cahier_de_textes.nil?

      cahier_de_textes.statistiques
    end

    desc 'valide toutes les saisies non validées de la classe'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :classe_id, desc: 'identifiant annuaire de la classe'
    }
    put '/:uai/classes/:classe_id' do
      cahier_de_textes = CahierDeTextes[ regroupement_id: params[:classe_id] ]

      error!( 'Classe inconnue', 404 ) if cahier_de_textes.nil?

      cahier_de_textes.valide!
    end

    desc 'statistiques des cahiers de textes par enseignants/mois'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
    }
    get '/:uai/enseignants' do
      Etablissement.where(uai: params[:uai]).first.statistiques_enseignants
    end

    desc 'saisies détaillées d\'un enseignant dans les cahiers de textes par mois/classes'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :enseignant_id, desc: 'identifiant annuaire de l\'enseignant'
    }
    get '/:uai/enseignants/:enseignant_id' do
      Etablissement.where(uai: params[:uai]).first.saisies_enseignant( params[:enseignant_id] )
    end

    desc 'valide toutes les saisies non validées de l\'enseignant'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :enseignant_id
      optional :debut, type: Time
      optional :fin, type: Time
    }
    put '/:uai/enseignants/:enseignant_id' do
      # TODO: prendre en compte debut et fin

      Etablissement.where(uai: params[:uai]).first.valide_enseignant!( params[:enseignant_id] )
    end

  end
end
