# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class UsersAPI < Grape::API

      desc 'renvoi les infos de l\'utilisateur identifié'
      get '/current' do
        utilisateur = env['rack.session'][:current_user]

        extra = Annuaire.get_user( utilisateur[ 'uid' ] )
        utilisateur[ 'profils' ] = extra['profils'].map do |profil|
          # renommage de champs
          profil['type'] = profil['profil_id']
          profil['uai'] = profil['etablissement_code_uai']
          profil['etablissement'] = profil['etablissement_nom']
          profil['nom'] = profil['profil_nom']

          # calcule du droit d'admin, true pour les TECH et les ADM
          profil['admin'] = extra['roles'].select { |r| r['etablissement_code_uai'] == profil['etablissement_code_uai'] && ( r['role_id'] == 'TECH' || r['role_id'].match('ADM.*') ) }.length > 0

          profil
        end
        utilisateur[ 'enfants' ] = extra [ 'enfants' ]

        regroupements_annuaire = Annuaire.get_user_regroupements( utilisateur[ 'uid' ] )
        utilisateur[ 'classes' ] = regroupements_annuaire[ 'classes' ]
                                   .concat( regroupements_annuaire['groupes_eleves'] )
                                   .concat( regroupements_annuaire['groupes_libres'] )
                                   .map do |regroupement|
          if regroupement.key? 'groupe_id'
            regroupement['type'] = 'groupe'
            regroupement['classe_id'] = regroupement['groupe_id']
            regroupement['classe_libelle'] = regroupement['groupe_libelle']
          else
            regroupement['type'] = 'classe'
          end
          regroupement
        end

        parametres = UserParameters.where( uid: utilisateur[ 'uid' ] ).first
        parametres = UserParameters.create( uid: utilisateur[ 'uid' ] ) if parametres.nil?

        utilisateur['parametrage_cahier_de_textes'] = JSON.parse( parametres[:parameters] )

        utilisateur
      end

      desc 'efface toute trace de l\'utilisateur identifié'
      delete '/:id' do
        # TODO
        STDERR.puts "Deleteing all traces of #{params[:id]}"
      end

      desc 'Merge les données de l\'utilisateur source_id vers l\'utilisateur target_id'
      put '/:target_id/merge/:source_id' do
        # TODO
        STDERR.puts "Merging all data of #{params[:source_id]} into #{params[:target_id]}"
      end
    end
  end
end
