# -*- coding: utf-8 -*-

module ToDeepHashMixin
  def to_deep_hash
    # FIXME: ugly hack, JSON.parse to_json, really?!
    JSON.parse( to_json( include: self.class.associations ), symbolize_names: true )
  end
end
