#!/usr/bin/env ruby
# coding: utf-8

module DataBaseTypes
  class Presence
    def initialize(bits_table)
      @bits_table = bits_table
    end
    
    def enable_for_week?(n)
      @bits_table[n] == 1
    end
  end
end
