# -*- encoding: utf-8 -*-

module UserHelpers
  class HashIt
    def initialize( hash )
      hash.each do |k, v|
        instance_variable_set( "@#{k}", v )
        # create the getter
        self.class.send( :define_method, k, proc{ instance_variable_get( "@#{k}" ) } )
        # create the setter
        # self.class.send( :define_method, "#{k}=", proc{ |val| instance_variable_set( "@#{k}", val ) } )
      end
    end
  end

  class HashedUser < HashIt
    def is?( profil )
      # FIXME
      profils = Annuaire.get_user( @uid )['profils']
      @ENTPersonProfils.include? "#{profil}:#{profils[0]['uai']}"
    end
  end

  def user
    HashedUser.new env['rack.session'][:current_user]
  end
end
