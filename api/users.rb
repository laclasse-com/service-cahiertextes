# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class UsersAPI < Grape::API

    desc 'renvoi les infos de l\'utilisateur identifié'
    get '/current' do
       utilisateur = env['rack.session'][:current_user]
       # utilisateur['classes'] = [] unless utilisateur.has_key? 'classes'
       utilisateur[ 'extra' ] = Annuaire.get_user( utilisateur[ 'uid' ] )
       utilisateur['classes'] = utilisateur[ 'extra' ][ 'classes' ]
       utilisateur['classes'] = utilisateur['classes'].map { |classe|
          classe['regroupement_id'] = classe['classe_id']

          classe
       }

       # FIXME: DEBUG
       p utilisateur['ENTPersonProfils']
       utilisateur['ENTPersonProfils'] = 'ENS:0699999Z' if utilisateur['uid'] == 'VAA62559'
       #utilisateur['classes'] = [{regroupement_id: 23}, {regroupement_id: 24} ] if utilisateur['uid'] == 'VAA62559'

       utilisateur
    end

    desc 'efface toute trace de l\'utilisateur identifié'
    delete '/:id' do
       # TODO
       STDERR.puts "Deleteing all traces of #{params[:id]}"
    end

    desc 'efface toute trace de l\'utilisateur identifié'
    put '/:target_id/merge/:source_id' do
       # TODO
       STDERR.puts "Merging all data of #{params[:source_id]} into #{params[:target_id]}"
    end

  end
end
