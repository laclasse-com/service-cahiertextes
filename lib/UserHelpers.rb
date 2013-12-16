# -*- encoding: utf-8 -*-

module UserHelpers

   def user
      env['rack.session'][:current_user]
   end

   def user_profils
      user[:info].to_hash['profils'] unless user[:info].to_hash['profils']
      []
   end

   def user_classes
      user[:info].to_hash['classes'] unless user[:info].to_hash['classes'].nil?
      []
   end

   def user_uid
      user[:info].to_hash['uid']
   end

end
