# Copyright (c) 2005 Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
require 'acts_as_immutable'

ActiveRecord::Base.send :include, Peerworks::ActsAsImmutable