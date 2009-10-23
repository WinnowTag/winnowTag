# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a configuration option of Winnow.
class Setting < ActiveRecord::Base
  validates_presence_of :name, :value
end
