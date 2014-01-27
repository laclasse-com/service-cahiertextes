# -*- encoding: utf-8 -*-

module UserHelpers

   def user
      env['rack.session'][:current_user]
   end

   def user_is_prof?( uai )
      # if user['ENTPersonProfils'].index("ENS:#{uai}")
      # FIXME: DEBUG: remove right for DIR
      if user['ENTPersonProfils'].index("ENS:#{uai}") || user['ENTPersonProfils'].index("DIR:#{uai}")
         true
      else
         false
      end
   end

end
