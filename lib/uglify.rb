# -*- coding: utf-8 -*-

module Uglify
  module_function

  def those_files( ary_files )
    Uglifier.compile( ary_files.map { |fichier| File.read( fichier ) }.join, harmony: true )
  end

  def those_files_with_map( ary_files )
    Uglifier.compile_with_map( ary_files.map { |fichier| File.read( fichier ) }.join, harmony: true )
  end
end
