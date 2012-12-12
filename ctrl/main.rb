# Default url mappings are:
# 
# * a controller called Main is mapped on the root of the site: /
# * a controller called Something is mapped on: /something
# 
# If you want to override this, add a line like this inside the class:
#
#  map '/otherurl'
#
# this will force the controller to be mounted on: /otherurl.
class MainController < Controller
  # the index action is called automatically when no other action is specified
  def index
    @appname = 'CTXTv2'
    @title = 'Cahier de textes'
    @meta_desc = "Some keywords,"
    @meta_author = "Pierre-Gilles Levallois / ERASME 2012"
  end
end
