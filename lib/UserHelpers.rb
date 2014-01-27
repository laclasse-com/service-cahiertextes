# -*- encoding: utf-8 -*-

module UserHelpers
   @@user = nil

   class HashIt
      def initialize( hash )
         hash.each do |k, v|
            self.instance_variable_set( "@#{k}", v )
            # create the getter
            self.class.send(:define_method, k, proc{ self.instance_variable_get( "@#{k}" ) } )
            # create the setter
            # self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
         end
      end
   end

   class HashedUser < HashIt
      def is?( profil, uai )
         if @ENTPersonProfils.index("#{profil}:#{uai}")
            true
         else
            false
         end
      end
   end

   def user
      @@user = HashedUser.new env['rack.session'][:current_user] if @@user.nil?

      @@user
   end
end
