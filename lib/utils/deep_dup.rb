# -*- encoding: utf-8 -*-

module Utils
  module_function

  def deep_dup( thing )
    Marshal.load( Marshal.dump( thing ) ) # rubocop:disable Security/MarshalLoad
  end
end
