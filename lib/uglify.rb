# -*- coding: utf-8 -*-

module Uglify
  module_function

  def those_files( ary_files, options = nil )
    Uglifier.compile( ary_files.map { |fichier| File.read( fichier ) }.join, options )
  end

  def those_files_with_map( ary_files, options = nil )
    Uglifier.compile_with_map( ary_files.map { |fichier| File.read( fichier ) }.join, options )
  end
end
