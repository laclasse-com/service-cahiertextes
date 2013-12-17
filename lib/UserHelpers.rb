# -*- encoding: utf-8 -*-

module UserHelpers

   def user
      env['rack.session'][:current_user]
   end

   def user_profils
      user['profils'] unless user[:info].to_hash['profils']
      []
   end

   def user_classes
      user['classes'] unless user[:info].to_hash['classes'].nil?
      []
   end

   def user_uid
      user['uid']
   end

end
