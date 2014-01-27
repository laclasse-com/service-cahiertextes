# -*- encoding: utf-8 -*-

module UserHelpers

   def user
      env['rack.session'][:current_user]
   end

   def user_is?( profil, uai )
      if user['ENTPersonProfils'].index("#{profil}:#{uai}")
         true
      else
         false
      end
   end

end
