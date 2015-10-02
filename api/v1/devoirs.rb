# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    # API d'accès aux devoirs
    # Utilisée par les :
    #   - élèves pour consultation et gestion todo-list
    #   - enseignants pour consultation et édition
    #   - principaux pour consultation
    class DevoirsAPI < Grape::API
      desc 'renvoi tous les devoirs concernant l\'utilisateur durant la période donnée'
      params do
        optional :debut, type: Date
        optional :fin, type: Date
        optional :uid
      end
      get '/' do
        if params[:uid]
          user_annuaire = AnnuaireWrapper::User.get( user[:uid] )
          error!( '401 Unauthorized', 401 ) unless user_annuaire['profils']
                                                   .find do |p|
            p['actif']
          end['profil_id'] == 'TUT' &&
                                                   !( user_annuaire['enfants']
                                                      .find { |e| e['enfant']['id_ent'] == params[:uid] }.nil? )

          regroupements_annuaire = AnnuaireWrapper::User.get_regroupements( params[:uid] )
        else
          regroupements_annuaire = AnnuaireWrapper::User.get_regroupements( user[:uid] )
        end

        regroupements_ids = regroupements_annuaire['classes']
                            .concat( regroupements_annuaire['groupes_eleves'] )
                            .concat( regroupements_annuaire['groupes_libres'] )
                            .reject { |regroupement| regroupement['etablissement_code'] != params[:uai] if params[:uai] }
                            .map do |regroupement|
          if regroupement.key? 'classe_id'
            regroupement['classe_id']
          elsif regroupement.key? 'groupe_id'
            regroupement['groupe_id']
          elsif regroupement.key? 'id'
            regroupement['id']
          end
        end
                            .uniq

        if params[:debut].nil? || params[:fin].nil?
          devoirs = Devoir
                    .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :creneau_emploi_du_temps_id)
                    .where( regroupement_id: regroupements_ids )
                    .where( deleted: false )
        else
          devoirs = Devoir
                    .join(:creneaux_emploi_du_temps_regroupements, creneau_emploi_du_temps_id: :creneau_emploi_du_temps_id)
                    .where( regroupement_id: regroupements_ids )
                    .where( deleted: false )
                    .where( date_due: params[:debut] .. params[:fin] )
        end

        devoirs.map do |devoir|
          devoir.to_deep_hash( uid: params[:uid] ? params[:uid] : user[:uid] )
        end
      end

      desc 'renvoi le détail d\'un devoir'
      params do
        requires :id
      end
      get '/:id' do
        devoir = Devoir[ params[:id] ]

        error!( 'Devoir inconnu', 404 ) if devoir.nil? ||
                                           ( devoir.deleted && devoir.date_modification < UNDELETE_TIME_WINDOW.minutes.ago )

        devoir.to_deep_hash( user )
      end

      desc 'renseigne un devoir'
      params do
        requires :type_devoir_id
        requires :contenu
        requires :creneau_emploi_du_temps_id
        requires :date_due, type: Date

        optional :cours_id
        optional :regroupement_id
        optional :ressources
        optional :temps_estime
      end
      post  do
        user_needs_to_be( %w( ENS DOC ), true )

        error!( 'Créneau invalide', 409 ) if CreneauEmploiDuTemps[ params[:creneau_emploi_du_temps_id] ].nil?

        devoir = Devoir.create( type_devoir_id: params[:type_devoir_id],
                                creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                contenu: params[:contenu],
                                date_due: params[:date_due],
                                temps_estime: params[:temps_estime],
                                date_creation: Time.now )

        if params[ :cours_id ] && !params[ :cours_id ].nil?
          devoir.update( cours_id: params[:cours_id] )
        else
          cours = Cours.where( creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id] )
                  .where( date_cours: params[:date_due] )
                  .where( deleted: false )
                  .first
          if cours.nil?
            cahier_de_textes = CahierDeTextes.where( regroupement_id: params[:regroupement_id] ).first
            cahier_de_textes = CahierDeTextes.create( date_creation: Time.now,
                                                      regroupement_id: params[:regroupement_id] ) if cahier_de_textes.nil?

            cours = Cours.create( enseignant_id: user[:uid],
                                  cahier_de_textes_id: cahier_de_textes.id,
                                  creneau_emploi_du_temps_id: params[:creneau_emploi_du_temps_id],
                                  date_cours: params[:date_due],
                                  date_creation: Time.now,
                                  contenu: '' )
          end
          devoir.update( cours_id: cours.id )
        end

        devoir.modifie( params )

        devoir.to_deep_hash
      end

      desc 'modifie un devoir'
      params do
        requires :id
        requires :type_devoir_id
        requires :contenu
        requires :creneau_emploi_du_temps_id
        requires :date_due, type: Date

        optional :cours_id
        optional :ressources
        optional :temps_estime
      end
      put '/:id' do
        user_needs_to_be( %w( ENS DOC ), true )

        devoir = Devoir[ params[:id] ]
        error!( 'Devoir inconnu', 404 ) if devoir.nil?

        devoir.modifie( params )

        devoir.to_deep_hash
      end

      desc 'copie un devoir pour le rattacher à une autre SP et un créneau et une date_due différente'
      params do
        requires :id
        requires :cours_id
        requires :creneau_emploi_du_temps_id
        requires :date_due
      end
      put '/:id/copie/cours/:cours_id/creneau_emploi_du_temps/:creneau_emploi_du_temps_id/date_due/:date_due' do
        user_needs_to_be( %w( ENS DOC ), true )

        devoir = Devoir[ params[:id] ]
        error!( 'Devoir inconnu', 404 ) if devoir.nil?

        devoir.copie( params[:cours_id], params[:creneau_emploi_du_temps_id], params[:date_due] )

        devoir
      end

      desc 'marque un devoir comme fait'
      params do
        requires :id
      end
      put '/:id/fait' do
        user_needs_to_be( %w( ELV ), true )

        devoir = Devoir[ params[:id] ]
        error!( 'Devoir inconnu', 404 ) if devoir.nil?

        devoir.toggle_fait( user )

        devoir.to_deep_hash( user )
      end

      desc 'marque un devoir comme éffacé et inversement'
      params do
        requires :id
      end
      delete '/:id' do
        user_needs_to_be( %w( ENS DOC ), true )

        devoir = Devoir[ params[:id] ]
        error!( 'Devoir inconnu', 404 ) if devoir.nil?

        devoir.toggle_deleted

        devoir.to_deep_hash( user )
      end
    end
  end
end
