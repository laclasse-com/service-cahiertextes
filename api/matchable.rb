# -*- coding: utf-8 -*-

require_relative '../models/models'

module CahierDeTextesApp
  class MatchableAPI < Grape::API
    format :json

    before do
      user_needs_to_be( %w( DIR ENS DOC ), true )
    end

    desc 'Get a match'
    params do
      requires :hash
    end
    get '/:hash' do
      fi = Matchable[ hash: params[:hash] ]
      error!( "No match for #{params[:hash]}", 404 ) if fi.nil?

      fi
    end

    desc 'Identifie une Matière/Regroupement/Personne-Non-Identifié en lui donnant un ID Annuaire manuellement'
    params do
      requires :hash
      requires :id_annuaire
    end
    post '/:hash' do
      fi = Matchable[ hash: params[:hash] ]
      fi = Matchable.create( hash: params[:hash] ) if fi.nil?

      fi.update( id_annuaire: params[:id_annuaire] )
      fi.save

      fi
    end

    desc 'Delete a match'
    params do
      requires :hash
    end
    delete '/:hash' do
      fi = Matchable[ hash: params[:hash] ]
      fi.destroy unless fi.nil?

      fi
    end
  end
end
