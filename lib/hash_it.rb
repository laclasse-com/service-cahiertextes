# encoding: utf-8

class HashIt
  def initialize( hash )
    hash.each do |k, v|
      instance_variable_set( "@#{k}", v )
      # create the getter
      self.class.send( :define_method, k, proc { instance_variable_get( "@#{k}" ) } )
      # create the setter
      # self.class.send( :define_method, "#{k}=", proc{ |val| instance_variable_set( "@#{k}", val ) } )
    end
  end
end
