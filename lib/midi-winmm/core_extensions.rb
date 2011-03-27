#!/usr/bin/env ruby

class Hash

  # change string keys to symbols
  def symbolize_keys!
    replace(inject({}) { |h,(k,v)| h[k.to_sym] = v; h })
  end

end