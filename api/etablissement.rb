# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class EtablissementAPI < Grape::API
    format :json

    desc 'statistiques des cahiers de textes par classes/mois/matières'
    params {
      requires :uai
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
      requires :id_classe
    }
    get '/:uai/classe/:id_classe' do
      cdt = CahierDeTextes[ regroupement_id: params[:id_classe] ]

      error!( 'Classe inconnue', 404 ) if cdt.nil?

      cdt.statistics
    end

    desc 'valide toutes les saisies non validées de la classe'
    params {
      requires :classe_id
    }
    put '/:uai/classe/:id_classe' do
      # TODO: validate all?
    end

    desc 'statistiques des cahiers de textes par enseignants/mois'
    get '/:uai/enseignants' do
      # TODO: get this from actual etablissement
      enseignants_ids = Cours.select( :enseignant_id ).all.uniq.map { |c| c.values[ :enseignant_id ] }

      enseignants_ids.map {
        |enseignant_id|
        { enseignant_id: enseignant_id,
          statistiques: (1..12).map {
            |month|
            stats = { month: month, total: 0, filled: 0, validated: 0 }

            CreneauEmploiDuTempsEnseignant.where( enseignant_id: enseignant_id ).map {
              |creneau|
              # TODO: prendre en compte les semaine_de_presence
              cours = Cours.where( creneau_emploi_du_temps_id: creneau.creneau_emploi_du_temps_id ).where( 'extract( month from date_cours ) = ' + month.to_s )

              # FIXME: calcul total attendu
              { total: 99,
                filled: cours.count,
                validated: cours.where( :date_validation ).count
              }
            }.each { |values| [:total, :filled, :validated].each { |key| stats[ key ] += values[ key ] } }
            stats
          }
        }
      }
    end

    desc 'statistiques des cahiers de textes d\'un enseignant par mois/classes'
    params {
      requires :id_enseignant
    }
    get '/:uai/enseignant/:id_enseignant' do
      # TODO
    end

    desc 'valide toutes les saisies non validées de l\'enseignant'
    params {
      requires :enseignant_id
      optional :debut, type: Time
      optional :fin, type: Time
    }
    put '/:uai/enseignant/:id_enseignant' do
        # TODO: validate all?
      end

  end
end
