# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  module V1
    class UsersAPI < Grape::API

      desc 'renvoi les infos de l\'utilisateur identifié'
      get '/current' do
        utilisateur = env['rack.session'][:current_user]

        extra = Annuaire.get_user( utilisateur[ 'uid' ] )
        utilisateur[ 'profils' ] = extra['profils'].map { |profil|
          # calcule du droit d'admin, true pour les TECH et les ADM
          is_admin = extra['roles'].select { |r| r['etablissement_code_uai'] == profil['etablissement_code_uai'] && ( r['role_id'] == 'TECH' || r['role_id'].match('ADM.*') ) }.length > 0

          { type: profil['profil_id'],
            uai: profil['etablissement_code_uai'],
            etablissement: profil['etablissement_nom'],
            nom: profil['profil_nom'],
            admin: is_admin
          }
        }

        utilisateur[ 'classes' ] = Annuaire.get_user_regroupements( utilisateur[ 'uid' ] )[ 'classes' ].map { |classe|
          classe[ 'regroupement_id' ] = classe[ 'classe_id' ]

          classe
        }

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
