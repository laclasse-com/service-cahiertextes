# -*- coding: utf-8 -*-

class CahierDeTextes < Sequel::Model( :cahiers_de_textes )
  def statistics
    # TODO: return statistics about this Cahier de textes
    { name: '6⁰Q' }
  end

  def content( debut, fin )
    # TODO: return the content of this Cahier de textes during the given dates interval
    {}
  end
end
