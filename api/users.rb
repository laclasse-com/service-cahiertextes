# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class UsersAPI < Grape::API

    desc 'renvoi les infos de l\'utilisateur identifié'
    get '/current' do
       utilisateur = env['rack.session'][:current_user]
       utilisateur['classes'] = [] unless utilisateur.has_key? 'classes'

       utilisateur
    end

    desc 'efface toute trace de l\'utilisateur identifié'
    delete '/:id' do
       STDERR.puts "Deleteing all traces of #{params[:id]}"
    end

    desc 'efface toute trace de l\'utilisateur identifié'
    put '/:target_id/merge/:source_id' do
       STDERR.puts "Merging all data of #{params[:source_id]} into #{params[:target_id]}"
    end

  end
end
