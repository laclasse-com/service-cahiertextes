# -*- coding: utf-8 -*-

module CahierDeTextesAPI
  class DevoirToDoAPI < Grape::API

    desc 'permet de noter un devoir comme fait/à faire'
    params {
      requires :devoir_id
    }
    put '/:devoir_id' do
      # FIXME: get real (Élève) user
      eleve_id = 1

      Devoir[ params[:devoir_id] ].fait_par( eleve_id )
    end

  end
end
