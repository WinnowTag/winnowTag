# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Captures the functionality required for a Class to be taggable.
#
# Currently this just creates the tagging associations and adds a method
# to the taggable to get all the taggings for a list of taggers, see
# taggings_by_taggers.
#
# To make an ActiveRecord model a taggable, just call acts_as_taggable
# within the class definition.
#
# == Associations
#
# A taggable will have a polymorphic association created called taggings to
# the Tagging class. This association is extended with the FindByTagger module.
#
module Taggable  
  module Acts # :nodoc:
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end
    module ClassMethods
      def acts_as_taggable(options = {})
        include Taggable
      end
    end
  end
  
  # Module for extending tagging associations with a find_by_tagger method.
  #
  # This also adds some trickery that allows us to cache some taggings so we can
  # load all the taggings for the current feed items into memory at once instead
  # of using a query for each feed item.
  #
  # See FeedItem.find_by_filters for how this is done.
  #
  module FindByTagger    
    def cached_taggings
      if @cached_taggings.nil?
        @cached_taggings = Hash.new([])
      end
      
      @cached_taggings
    end
    
    def find_by_tagger_with_caching(tagger, tag = nil)
      taggings = cached_taggings[tagger].select do |tagging|
        (tag.nil? or tagging.tag == tag)
      end
        
      cached_taggings.has_key?(tagger) ? taggings : find_by_tagger_without_caching(tagger, tag)
    end
    
    # Finds all taggings on this taggable by the given tagger.  You can also constrain
    # it to just taggings by a given tagger with a given tag by passing the tag in as
    # the second variable.
    #
    # This is an extension on the taggings association so use it like so:
    #
    #   taggable.taggings.find_by_tagger(tagger, tag)
    #
    def find_by_tagger(tagger, tag = nil)
      conditions = 'taggings.tagger_type = ? and taggings.tagger_id = ? '
      conditions += ' and taggings.tag_id = ?' if tag
      conditions = [conditions, tagger.class.base_class.name, tagger.id]
      conditions += [tag.id] if tag

      find(:all, :conditions => conditions, :group => 'tag_id', :include => :tag, :order => 'tags.name ASC')
    end
    
    alias_method_chain :find_by_tagger, :caching
  end
    
  # This creates the tagging associations on a class that calls acts_as_taggable.
  def self.included(base) # :nodoc:
    base.has_many :taggings, :dependent => :delete_all, :as => :taggable, :extend => FindByTagger
  end
      
  # Gets taggings between a list of taggers and this taggable.
  #
  # The priority functionality of this method is used to enforce the user taggings overriding classifier
  # taggings in the display.
  #
  # === Parameters
  #
  # <tt>taggers</tt>::
  #    An array of taggers to get the taggings for.  The order of the array enforces the priority
  #    of the taggings.
  # <tt>:all_taggings</tt> <em>(true|false)</em>:: 
  #    If true return all taggings, not just the positive or priority ones. The default is false.
  #
  # === Return Structure
  #
  # The <tt>all_taggings</tt> option defines the struture of the returned object.
  #
  # The structure when true will be a 2D array where each element is an array with the first 
  # element being the tag and the second element being an array of taggings using that tag, 
  # in order of the taggers array.
  #
  # If false the structure will be a 2D array where the first element of each sub-array is the tag and the 
  # second element is the the first tagging for the tag as it appears in the order of the taggers array, i.e.
  # if the first tagger has a 'foo' tag and the second tagger also has a 'foo' tag, only the tagging from the
  # first tagger will be returned.
  #
  def taggings_by_taggers(taggers, options = {})
    options.assert_valid_keys([:all_taggings])    
    taggers = Array(taggers)
    taggings = []

    taggers.each do |tagger|
      taggings += self.taggings.find_by_tagger(tagger)   
    end
    
    # Reverse it so items by taggers earlier in the list beat items by later taggers
    taggings_by_tag = taggings.reverse.inject({}) do |hash, tagging|
      if options[:all_taggings]
        hash[tagging.tag] = Array(hash[tagging.tag]).unshift(tagging)
      else
        hash[tagging.tag] = tagging
      end
      hash
    end
    
    taggings_by_tag.select{|tag, tagging|       
        options[:all_taggings] or tagging.nil? or tagging.positive? or tagging.borderline?
    }.to_a.sort_by {|e| 
      e.first
    }
  end
end
ActiveRecord::Base.send(:include, Taggable::Acts)
