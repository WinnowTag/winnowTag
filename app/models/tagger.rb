# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Captures all the functionality required for a Class to be tagger.
#
# This create the associations from a tagger to Tagging and
# to Tag through Tagging.
#
# A class can become a tagger by calling <tt>acts_as_tagger</tt> in
# it's definition.  See Acts::ClassMethods for
# more information.
#
# Tagger also contains a number of methods to get information about the taggings of a tagger. These are:
#
# * average_taggings_per_item
# * last_tagging_on
# * number_of_tagged_items
# * tagging_percentage
#
#
module Tagger
  module Acts #:nodoc:
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end
    module ClassMethods 
      # An ActiveRecord::Base subclass can call this within its
      # class definition to become a tagger.
      #
      # === Parameters
      # By default, a tagging created by this tagger will be assumed to be positive only if
      # its strength is == 1.  This can be overriden to provide another sql snippet that
      # determines tagging positivity, for example:
      #
      #   acts_as_tagger :positive_condition => 'taggings.strength > 0.9'
      #
      # will interpret all taggings with a strength greater than 0.9 as positive.
      #
      # You can also provide a string pattern to make this more dynamic, for example:
      #
      #   acts_as_tagger :positive_condition => 'taggings.strength > #{positive_cutoff}'
      #
      # will cause the string to be interpreted at run time to use the value of positive_cutoff.
      #
      # If you do provide a positive condition, you also need to override positive_tagging? to make
      # it consistent with your definition for tagging positivity.
      #
      def acts_as_tagger(options = {})
        cattr_accessor :positive_condition
        self.positive_condition = (options[:positive_condition] or 'taggings.strength = 1')
        include Tagger
      end
    end
  end
  
  def self.included(base) # :nodoc:
    base.has_many :taggings, :as => :tagger, :dependent => :delete_all, :extend => FindByTaggable
    base.has_many :tags, :through => :taggings, :select => 'DISTINCT tags.*', 
                  :order => 'tags.name ASC', :extend => FindByTaggable, 
                  :conditions => 'taggings.deleted_at is null'
  end
  
  # Returns true if the tagging meets the condition for positivity defined by this tagger.
  # By default this is the tagging has a strength equal to 1. 
  #
  # This should be overriden by the base class of the tagger if the tagger provides
  # a positive_condition argument to acts_as_tagger.
  #
  def positive_tagging?(tagging)
    tagging.strength == 1
  end
  
  # Returns an SQL fragment that can be used to constrain a query on the tagging table
  # to only return taggings from this tagger
  def tagging_sql(include_negative = false)
    if include_negative
      "(taggings.tagger_id = #{self.id} and taggings.tagger_type = '#{self.class.name}')"
    else
      "(taggings.tagger_id = #{self.id} and taggings.tagger_type = '#{self.class.name}' and #{positive_condition_sql})"
    end
  end
  
  def positive_condition_sql(table_alias = Tagging.table_name)
    # This is eval'ed because the positive condition sql snippet can be defined with 
    # single quotes to lazily interpolate values
    eval(%Q("#{positive_condition.gsub(Tagging.table_name, table_alias)}"))
  end
  
  # Get the the strength of a tag on a taggable.
  # Will return nil for no tagging or a value from 0 - 1
  #
  def tagging_strength_for(tag, on)
    tagging = self.taggings.find_by_taggable(on, :first, :conditions => ['tag_id = ?', tag.id])
    tagging.strength unless tagging.nil?
  end
  
  def copy_tag(from, to, to_tagger = self)
    if from == to and self == to_tagger
      raise ArgumentError, "Can't copy tag to tag of the same name."
    end
    
    if self != to_tagger and to_tagger.tags.include?(to)
      raise ArgumentError, "Target tagger already has a #{to.name} tag"
    end
    
    self.taggings.find_by_tag(from).each do |tagging|
      to_tagger.taggings.create(:tag => to, :taggable => tagging.taggable, :strength => tagging.strength)
    end
  end

  # Gets a list of tags with a count of their usage for this user.
  #
  # This will be made of all tags the use currently has applied on items.
  #
  def tags_with_count(options = {})
    options.assert_valid_keys(:feed_filter, :text_filter)
    pos_condition = positive_condition_sql
    joins = []
    
    if options[:feed_filter]
      if !options[:feed_filter][:include].empty? or !options[:feed_filter][:exclude].empty?
        feed_joins = "INNER JOIN feed_items ON taggings.taggable_id = feed_items.id AND taggings.taggable_type = 'FeedItem'"
      
        if !options[:feed_filter][:include].empty?
          feed_joins << " AND feed_items.feed_id IN (#{options[:feed_filter][:include].join(",")})"
        end
      
        if !options[:feed_filter][:exclude].empty?
          feed_joins << " AND feed_items.feed_id NOT IN (#{options[:feed_filter][:exclude].join(",")})"
        end
        
        joins << feed_joins
      end
    end
        
    if options[:text_filter]
      joins << " INNER JOIN feed_item_contents_full_text on taggings.taggable_id = feed_item_contents_full_text.id" +
                  " and taggings.taggable_type = 'FeedItem'" +
                  " and MATCH(content) AGAINST(#{connection.quote(options[:text_filter])} in boolean mode)"
    end

    tag_list = self.tags.find(:all, 
       :select => 'tags.name, tags.id, ' +
                  "count(IF(#{pos_condition}, 1, NULL)) as count, " +
                  'count(IF(taggings.strength = 0, 1, NULL)) as negative_count',
       :joins => joins.join(' '),
       :group => 'tags.id',
       :order => 'tags.name ASC'
     )

    if options[:feed_filter] and !options[:feed_filter][:include].empty?
      # if feed was specified we need to fold it into the entire list of tags
      all_tags = self.tags.find(:all, :select => "distinct tags.name, tags.id, '0' as count")

      # index by id
      tags_by_id = tag_list.inject(Hash.new) do |hash, tag|
        hash[tag.id] = tag
        hash
      end

      tag_list = all_tags.map do |tag|
        (tags_by_id[tag.id] or tag)
      end
    end

    tag_list
  end

  # Gets the number of items tagged by this tagger
  def number_of_tagged_items
    self.taggings.find(:first, :select => 'count(distinct taggable_id, taggable_type) as count').count.to_i
  end

  # Gets the percentage of items tagged by this tagger
  def tagging_percentage(klass = FeedItem)
    100 * number_of_tagged_items.to_f / klass.count
  end

  # Gets the date the tagger last created a tagging.
  def last_tagging_on
    last_tagging = self.taggings.find(:first, :order => 'taggings.created_on DESC')

    last_tagging ? last_tagging.created_on : nil
  end

  # Gets the average number of tags a user has applied to an item.
  def average_taggings_per_item
    Tagging.find_by_sql(<<-END_SQL
      select avg(count) as average from (
         select count(id) as count
         from taggings
         where
           tagger_type = 'User' and
           tagger_id = #{self.id} and
           deleted_at is null
         group by taggable_type, taggable_id
       ) as counts;
      END_SQL
    ).first.average.to_f
  end
   
  # Module to extend tagging assoaciations with a find by taggable method.
  module FindByTaggable
    def find_by_taggable(taggable, type = :all, options = {})
      with_scope(:find => {:conditions => 
          ['taggings.taggable_type = ? and taggings.taggable_id = ?', taggable.class.base_class.name.to_s, taggable.id]}) do
        find(type, options)
      end
    end

    def find_by_tag(tag, type = :all, options = {})
      with_scope(:find => {:conditions => ['taggings.tag_id = ?', tag.id]}) do
        find(type, options)
      end
    end
  end
end

ActiveRecord::Base.send(:include, Tagger::Acts)
