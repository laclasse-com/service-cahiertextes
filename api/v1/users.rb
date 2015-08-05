# -*- coding: utf-8 -*-

require_relative '../../lib/data_management'

module CahierDeTextesAPI
  module V1
    class UsersAPI < Grape::API
      desc 'renvoi les infos de l\'utilisateur identifié'
      get '/current' do
        utilisateur = user_verbose

        parametres = UserParameters.where( uid: utilisateur[ :uid ] ).first
        parametres = UserParameters.create( uid: utilisateur[ :uid ] ) if parametres.nil?
        parametres.update( date_connexion: Time.now )
        parametres.save

        utilisateur[ 'parametrage_cahier_de_textes' ] = JSON.parse( parametres[:parameters] )

        matieres = AnnuaireWrapper::Matiere.query

        utilisateur[ 'profils' ].select do |profil|
          profil['profil_id'] == 'DIR' || profil['profil_id'] == 'EVS'
        end.each do |profil|
          profil['matieres'] = matieres
        end

        utilisateur
      end

      desc 'met à jour les paramètres utilisateurs'
      params do
        requires :parametres, type: String
      end
      put '/current/parametres' do
        parametres = UserParameters.where( uid: user[:uid] ).first

        parametres.update( parameters: params[:parametres] )
        parametres.save

        user_verbose
      end

      desc 'efface toute trace de l\'utilisateur identifié'
      delete '/:uid' do
        user_needs_to_be( [], true )

        DataManagement::User.delete( params[:uid] )
      end

      desc 'Merge les données de l\'utilisateur source_id vers l\'utilisateur target_id'
      put '/:target_uid/merge/:source_uid' do
        user_needs_to_be( [], true )

        DataManagement::User.merge( params[:target_uid], params[:source_uid] )
      end
    end
  end
end
