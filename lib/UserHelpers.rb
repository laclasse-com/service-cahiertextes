# -*- encoding: utf-8 -*-

module UserHelpers

   def user
      env['rack.session'][:current_user]
   end

end
