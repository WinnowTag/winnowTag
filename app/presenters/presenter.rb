# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class Presenter
  attr_accessor :current_user

  def initialize(options = {})
    options.each do |key, value|
      send "#{key}=", value
    end
  end
end