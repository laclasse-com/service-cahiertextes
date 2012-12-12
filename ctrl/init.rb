# Define a subclass of Ramaze::Controller holding your defaults for all controllers. Note 
# that these changes can be overwritten in sub controllers by simply calling the method 
# but with a different value.

class Controller < Ramaze::Controller
  layout :default
  helper :xhtml, :user
  engine :etanni

  before_all do
    #Init current user with the cas attributs
    cas_attr = request.env['rack.session'][:cas] unless request.env['rack.session'].nil?
    user_login(cas_attr) unless cas_attr.nil?
  end
end

# Here you can require all your other controllers. Note that if you have multiple
# controllers you might want to do something like the following:
#
#  Dir.glob('controller/*.rb').each do |controller|
#    require(controller)
#  end
#
require __DIR__('main')
