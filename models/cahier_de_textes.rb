# -*- coding: utf-8 -*-

class CahierDeTextes < Sequel::Model( :cahier_de_textes )
  def statistics
    {name: "6⁰Q"}
  end
end
