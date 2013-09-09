# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EtablissementAPI < Grape::API
    format :json

    desc 'statistiques des cahiers de textes par classes/mois/matières'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
    }
    get '/:uai/classes' do
      # TODO: get this from actual etablissement
      regroupements_ids = [ 1, 2, 3, 4, 5, 12 ] # get_classes_from_etablissement( params[:uai] )

      regroupements_ids.map {
        |regroupement_id|
        CahierDeTextes[ regroupement_id: params[:id] ] && CahierDeTextes[ regroupement_id: regroupement_id ].statistics || {}
      }.select{ |item| !item.empty? }
    end

    desc 'statistiques du cahier de textes d\'une classe'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :classe_id, desc: 'identifiant annuaire de la classe'
    }
    get '/:uai/classe/:classe_id' do
      cdt = CahierDeTextes[ regroupement_id: params[:classe_id] ]

      error!( 'Classe inconnue', 404 ) if cdt.nil?

      cdt.statistics
    end

    desc 'valide toutes les saisies non validées de la classe'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :classe_id, desc: 'identifiant annuaire de la classe'
    }
    put '/:uai/classe/:id_classe' do
      # TODO: validate all?
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
      requires :id_enseignant, desc: 'identifiant annuaire de l\'enseignant'
    }
    get '/:uai/enseignant/:id_enseignant' do
      Etablissement.where(uai: params[:uai]).first.saisies_enseignant( params[:id_enseignant] )
    end

    desc 'valide toutes les saisies non validées de l\'enseignant'
    params {
      requires :uai, desc: 'Code UAI de l\'établissement'
      requires :enseignant_id
      optional :debut, type: Time
      optional :fin, type: Time
    }
    put '/:uai/enseignant/:id_enseignant' do
        # TODO: validate all?
      end

  end
end
