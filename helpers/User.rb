# -*- encoding: utf-8 -*-

require_relative '../lib/HashedUser'

module UserHelpers
  def user
    HashedUser.new env['rack.session'][:current_user]
  end
end
