# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class Manager
  include ActionController::Translation

  def self.method_missing(method, *args)
    return super unless self.instance_methods.include?(method.to_s)

    response = self.new.send(method, *args)
    if block_given?
      yield response
    else
      return response
    end
  end
end
