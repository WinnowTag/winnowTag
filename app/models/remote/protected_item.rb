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
        # Need to build this path manually since ActiveResource is not exactly compatible
        # with Rails 1.2 routes for custom collection actions.  Should be fixed in 2.0.
        ActiveRecord::Base.benchmark("Deleting Protected Items") do
          connection.delete(collection_path(:protector_id => protector_id) + ";delete_all")
        end
        update(protector_id)
      end
    
      # Creates a protected item instance for an item.
      #
      # This is done in a thread so it never blocks the request cycle.
      # Don't access the DB in this thread though!
      #
      def protect_item(item, protector_id = ::Protector.id)
        Thread.new do
          self.create(:protector_id => protector_id, :feed_item_id => item.id)
        end
      end
      
      # Deletes a protected item instance for an item.
      #
      # This is done in a thread so it never blocks the request cycle.
      # Don't access the DB in this thread though!
      #
      def unprotect_item(item, protector_id = ::Protector.id)
        Thread.new do
          if item.taggings.empty?
            connection.delete(collection_path(:protector_id => protector_id) + ";delete_all" + 
                                                        query_string(:feed_item_id => item.id))
          end
        end
      end
    end
  end
end