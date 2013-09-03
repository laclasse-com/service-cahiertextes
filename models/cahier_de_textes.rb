# -*- coding: utf-8 -*-

class CahierDeTextes < Sequel::Model( :cahiers_de_textes )
  def statistics
    { name: '6⁰Q' }
  end
end
