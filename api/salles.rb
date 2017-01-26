# -*- coding: utf-8 -*-

module CahierDeTextesApp
  class SallesAPI < Grape::API
    desc 'renvoi toutes les salles'
    get '/' do
      Salle.all
    end

    desc 'renvoi une salle'
    params do
      requires :id
    end
    get '/:id' do
      salle = Salle[ params[:id] ]

      error!( "Salle #{params[:id]} inconnue", 404 ) if salle.nil?

      salle
    end

    desc 'crée une salle'
    params do
      optional :uai, desc: 'identifiant de l\'établissement'
      requires :identifiant, desc: 'identifiant de la salle dans l\'établissement'
      requires :nom, desc: 'nom de la salle'
    end
    post '/' do
      etablissement = Etablissement.where(uai: params[:uai]).first

      error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

      salle = DataManagement::Accessors.create_or_get( Salle,
                                                       # etablissement_id: etablissement.id,
                                                       identifiant: params[:identifiant] )
      salle.update( nom: params[:nom] )
      salle.save

      salle
    end

    desc 'mass creation of salles'
    params do
      requires :salles, type: Array
    end
    post '/bulk' do
      params[:salles].map do |salle|
        new_salle = DataManagement::Accessors.create_or_get( Salle,
                                                             identifiant: salle[:identifiant] )
        new_salle.update( nom: salle[:nom] )
        new_salle.save

        new_salle
      end
    end

    desc 'met à jour salle'
    params do
      requires :id

      optional :uai, desc: 'identifiant de l\'établissement'
      optional :identifiant, desc: 'identifiant de la salle dans l\'établissement'
      optional :nom, desc: 'nom de la salle'
    end
    put '/:id' do
      salle = Salle[ params[:id] ]

      error!( "Salle #{params[:id]} inconnue", 404 ) if salle.nil?

      if params.key? :uai
        etablissement = Etablissement.where(uai: params[:uai]).first

        error!( "Établissement #{params[:uai]} inconnu", 404 ) if etablissement.nil?

        salle.etablissement_id = params[:uai]
      end
      salle.identifiant = params[:identifiant] if params.key? :identifiant
      salle.nom = params[:nom] if params.key? :nom
      salle.save

      salle
    end

    desc 'détruit une salle'
    params do
      requires :id
    end
    delete '/:id' do
      salle = Salle[ params[:id] ]

      error!( "Salle #{params[:id]} inconnue", 404 ) if salle.nil?

      salle.destroy
    end
  end
end
