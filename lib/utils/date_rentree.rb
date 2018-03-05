module CahierDeTextesApp
  module Utils
    module_function

    def date_rentree
      Date.parse( "#{Date.today.month > 8 ? Date.today.year : Date.today.year - 1}-08-15" )
    end
  end
end
