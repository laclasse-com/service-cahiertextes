# -*- coding: utf-8 -*-

require_relative '../models/models'

module CahierDeTextesApp
  class MatchableAPI < Grape::API
    format :json

    before do
      user_needs_to_be( %w[ DIR ENS DOC ] )
    end

    desc 'Get all matches for a given UAI'
    params do
      requires :uai
    end
    get '/:uai' do
      etablissement = DataManagement::Accessors.create_or_get( Etablissement,
                                                               UAI: params[:uai] )

      Matchable.where( etablissement_id: etablissement.id ).all
    end

    desc 'Get a match'
    params do
      requires :uai
      requires :hash_item
    end
    get '/:uai/:hash_item' do
      etablissement = DataManagement::Accessors.create_or_get( Etablissement,
                                                               UAI: params[:uai] )

      fi = Matchable[ etablissement_id: etablissement.id,
                      hash_item: params[:hash_item] ]
      error!( "No match for #{params[:hash_item]}", 404 ) if fi.nil?

      fi
    end

    desc 'Identifie une Matière/Regroupement/Personne-Non-Identifié en lui donnant un ID Annuaire manuellement'
    params do
      requires :uai
      requires :hash_item
      requires :id_annuaire
    end
    post '/:uai/:hash_item' do
      etablissement = DataManagement::Accessors.create_or_get( Etablissement,
                                                               UAI: params[:uai] )

      fi = Matchable[ etablissement_id: etablissement.id, hash_item: params[:hash_item] ]
      fi = Matchable.create( etablissement_id: etablissement.id, hash_item: params[:hash_item] ) if fi.nil?

      fi.update( id_annuaire: params[:id_annuaire] )
      fi.save

      fi
    end

    desc 'Delete a match'
    params do
      requires :uai
      requires :hash_item
    end
    delete '/:uai/:hash_item' do
      etablissement = DataManagement::Accessors.create_or_get( Etablissement,
                                                               UAI: params[:uai] )

      fi = Matchable[ etablissement_id: etablissement.id,
                      hash_item: params[:hash_item] ]
      fi.destroy unless fi.nil?

      fi
    end
  end
end
