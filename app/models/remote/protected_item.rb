# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Remote
  class ProtectedItem < CollectorResource
    self.site += "/protectors/:protector_id"
    
    class << self
      def update(protector_id = ::Protector.id)
        items = Tagging.find(:all, :select => 'distinct feed_item_id',
                              :conditions => ['classifier_tagging = ?', false])
        if items.any?
          items_to_protect = items.map {|i| {:feed_item_id => i.feed_item_id} }
          ActiveRecord::Base.benchmark("Creating #{items_to_protect.size} Protected Items") do
            connection.post(collection_path(:protector_id => protector_id), 
                          items_to_protect.to_xml(:root => 'protected_items'))
          end
        end
      end
      
      def rebuild(protector_id = ::Protector.id)
        ActiveRecord::Base.benchmark("Deleting Protected Items") do
          delete(:delete_all, :protector_id => protector_id)
        end
        update(protector_id)
      end  
    end
  end
end