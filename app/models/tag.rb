# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# Convenience method for finding or creating a Tag by user and tag name
def Tag(user, tag)
  if tag.nil? || tag.is_a?(Tag) 
    tag
  else
    Tag.find_or_create_by_user_id_and_name(user.id, tag)
  end
end

# A Tag allows a User to give a name to FeedItem content.
#
# A Tag may be public, meaning that it is accessible to other users
# or private, meaning that is only accessible by the creator.
# 
# The bias attribute is passed to the classifier, it controls how sensitive
# classification of this tag will be. A bias of 1.0 is neutral, less that 1
# will err on the side of false negatives and a bias greater that 1 will
# err on the side of false positives.
#
# See also: Tagging
class Tag < ActiveRecord::Base  
  # Tag names can only contain basic ASCII characters, except period
  ASCII_CHARACTERS = %q{0-9a-zA-z ~!@#\$%^&*()_+`\-={}|\[\]\:";'<>?,\/}

  # The number of taggings suggestion before running the classifier
  cattr_accessor :undertrained_threshold
  @@undertrained_threshold = 6
  
  has_many :taggings, :dependent => :delete_all
  has_many :positive_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ? and strength = ?', false, 1]
  has_many :manual_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', false]
  has_many :classifier_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', true], 
            :dependent => :delete_all
  has_many :feed_items, :through => :taggings
  has_many :tag_subscriptions
  has_many :comments
  has_many :usages, :class_name => "TagUsage"
  belongs_to :user
  
  validates_presence_of :name
  validates_length_of :name, :within => 0...255
  validates_format_of :name, :with => /^[#{ASCII_CHARACTERS}]+$/, :allow_blank => true, :message => I18n.t("winnow.errors.tag.invalid_format")
  validates_uniqueness_of :name, :scope => :user_id, :case_sensitive => false

  # See the definition of this method below to learn about this callbacks
  before_save :set_sort_name

  # See long comment at definition of notify_subscriptions_of_name_change, below.
  # before_save :clear_subscriptions_unless_public

  before_save :notify_subscriptions_of_name_change

  # Reads the cached attribute or does a query to find the result. The cached attribute is set in the +search+ finder method.
  def positive_count
    read_attribute(:positive_count) || taggings.count(:conditions => "classifier_tagging = 0 AND taggings.strength = 1")
  end
  
  # Reads the cached attribute or does a query to find the result. The cached attribute is set in the +search+ finder method.
  def negative_count
    read_attribute(:negative_count) || taggings.count(:conditions => "classifier_tagging = 0 AND taggings.strength = 0")
  end
  
  # Reads the cached attribute or does a query to find the result. The cached attribute is set in the +search+ finder method.
  def feed_items_count
    read_attribute(:feed_items_count) || taggings.count(:select => "DISTINCT(feed_item_id)")
  end

  def classifier_count
    feed_items_count.to_i - positive_count.to_i - negative_count.to_i
  end
  
  # Reads the cached attribute or does a query to find the result. The cached attribute is set in the +search+ finder method.
  def last_trained
    if last_trained = read_attribute(:last_trained)
      Time.parse(last_trained)
    else
      if tagging = taggings.find(:first, :conditions => ['classifier_tagging = ?', false], :order => 'created_on DESC')
        tagging.created_on
      end
    end
  end
  
  # Provides the natural ordering of tags and their case-insensitive lexical ordering.
  def <=>(other)
    if other.is_a? Tag
      self.sort_name <=> other.sort_name
    else
      raise ArgumentError, I18n.t("winnow.errors.tag.compare_error", :other => other.class.name)
    end
  end
  
  # Copys a tag's bias, description, and taggings to another tag. Does not allow
  # copying to a tag that already has taggings.
  def copy(to)
    if self == to
      raise ArgumentError, I18n.t("winnow.errors.tag.copy_name_error")
    end
    
    if to.taggings.size > 0
      raise ArgumentError, I18n.t("winnow.errors.tag.copy_exists_error", :to => to.name)
    end
    
    Tagging.connection.execute(%Q|
      INSERT INTO taggings(feed_item_id, strength, classifier_tagging, created_on, tag_id, user_id)
      (SELECT feed_item_id, strength, classifier_tagging, created_on, #{to.id}, #{to.user_id} FROM taggings WHERE tag_id = #{self.id})
    |)
    
    to.bias = self.bias    
    to.description = self.description
    to.last_classified_at = self.last_classified_at
    to.save!
  end
  
  # Merges a tag's manual taggings with another tag's manual taggings.
  def merge(to)
    if self == to 
      raise ArgumentError, I18n.t("winnow.errors.tag.merge_name_error")
    end
    
    self.manual_taggings.each do |tagging|
      unless to.manual_taggings.exists?(['feed_item_id = ?', tagging.feed_item_id])
        to.user.taggings.create!(:tag => to, :feed_item_id => tagging.feed_item_id, :strength => tagging.strength)
      end
    end
    
    destroy
  end
  
  # Copys a tag to another tag, clearing the other tag's taggings first. See +Tag#copy+.
  def overwrite(to)
    to.taggings.clear
    self.copy(to)
  end

  def copy_to_archive
    # Make the tag and the subscriptions to it have the user_id of the "archive" account.
    # If the "archive" account already has a tag  or subscription with that name, use the
    # first available <from_name>_N where N starts with 2. Thus the first tag named "foo"
    # is archived as "foo", the second "foo_2", the third "foo_3", etc.

    archive_user = User.find_by_login("archive");
    archive_name = name
    if Tag.find_by_user_id_and_name(archive_user.id, archive_name)
      archive_name = name.gsub(/_\d*$/, '');
      i = 1;
      while Tag.find_by_user_id_and_name(archive_user.id, archive_name)
        i += 1;
        archive_name = name + '_' + i.to_s;
      end
    end

    to = Tag(archive_user, archive_name);

    copy(to);

    # TODO: Make this efficient for the case of a huge number of subscribers.
    TagSubscription.find_all_by_tag_id(id).each do |tag_subscription|
      if tag_subscription.user_id == archive_user.id
        tag_subscription.destroy
      else
        tag_subscription.update_attribute(:tag_id, to.id);
        tag_subscription.tag_archived(user.login);
        unless name == archive_name
          tag_subscription.tag_renamed(name, archive_name)
        end
      end
    end
  end
  
  def delete_classifier_taggings!
    Tagging.delete_all("classifier_tagging = 1 AND tag_id = #{self.id}")
  end
  
  def potentially_undertrained?
    self.positive_taggings.size < Tag.undertrained_threshold
  end
  
  # Create taggings for this tag from an atom document.
  def create_taggings_from_atom(atom)
    Tagging.transaction do 
      taggings_from_atom(atom)
    end
  end

  # Replace the taggings in this tag with the taggings in the atom document.
  def replace_taggings_from_atom(atom)
    Tagging.transaction do
      self.delete_classifier_taggings!
      taggings_from_atom(atom)      
    end
  end
  
  # Return an Atom document for this tag.
  #
  # When <tt>:training_only => true</tt> all and only training examples will be included
  # in the document and it will conform to the Training Definition Document.
  def to_atom(options = {})
    Atom::Feed.new do |feed|
      feed.title = "#{self.user.login}:#{self.name}"
      feed.id = "#{options[:base_uri]}/#{user.login}/tags/#{self.name}"
      feed.updated = self.updated_on
      feed[CLASSIFIER_NAMESPACE, 'classified'] << self.last_classified_at.xmlschema if self.last_classified_at
      feed[CLASSIFIER_NAMESPACE, 'bias'] << self.bias.to_s
      feed.categories << Atom::Category.new(:term => self.name, :scheme => "#{options[:base_uri]}/#{user.login}/tags/")
      
      feed.links << Atom::Link.new(:rel => "alternate", :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}.atom"))
      feed.links << Atom::Link.new(:rel => "#{CLASSIFIER_NAMESPACE}/edit", 
                                   :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}/classifier_taggings.atom"))
                         
      conditions = []
      condition_values = []
                
      if options[:training_only]
        conditions << 'classifier_tagging = 0'
        feed.links << Atom::Link.new(:rel => "self", :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}/training.atom"))
      else
        conditions << 'strength <> 0'
        feed.links << Atom::Link.new(:rel => "self", 
                                     :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}.atom"))
        feed.links << Atom::Link.new(:rel => "#{CLASSIFIER_NAMESPACE}/training", 
                                     :href => URI.escape("#{options[:base_uri]}/#{user.login}/tags/#{self.name}/training.atom"))     
      end
      
      if options[:since]
        conditions << 'taggings.created_on > ?'
        condition_values << options[:since].getutc
      end
      
      self.taggings.find(:all, :conditions => [conditions.join(" and "), *condition_values], 
                               :limit => (options[:training_only] ? nil : (options[:limit] or 100)),
                               :order => 'feed_items.updated DESC', :include => [{:feed_item, :content}]).each do |tagging|
        feed.entries << tagging.feed_item.to_atom(options.merge({:include_tags => self, :training_only => options[:training_only]}))
      end
    end
  end

  # Gets all the db ids for the tags - used to cheaply generate Etags of the tag index.
  def self.all_ids
    self.find(:all, :select => 'id').map(&:id)
  end
  
  # Generates the atom version of the tag index for the entire system.
  def self.to_atom(options = {})
    Atom::Feed.new do |feed|
      feed.title = "Winnow tags"
      feed.updated = Tag.maximum(:created_on)
        
      Tag.find(:all, :include => :user).each do |tag|
        feed.entries << Atom::Entry.new do |entry|
          entry.title = tag.name
          entry.id    = "#{options[:base_uri]}/#{tag.user.login}/tags/#{tag.name}"
          entry.updated = tag.updated_on
          entry.links << Atom::Link.new(:rel => "#{CLASSIFIER_NAMESPACE}/training", 
                                        :href => URI.escape("#{options[:base_uri]}/#{tag.user.login}/tags/#{tag.name}/training.atom"))
        end
      end
    end
  end
  
  # Creates a tag from an atom document. This atom document should be 
  # a training document that contains all the items that are manually
  # tagged within this tag.
  def self.create_from_atom(atom)
    if category = atom.categories.first    
      tag = self.create(:name => atom.title.to_s, 
                        :description => "Imported on #{Time.now}", 
                        :bias => atom[CLASSIFIER_NAMESPACE, 'bias'].first)
           
      if tag.valid?           
        atom.entries.each do |e|
          ecat = e.categories.first
        
          strength = if ecat && category.scheme == ecat.scheme && category.term == ecat.term
            1.0
          elsif e.links.detect {|l| l.href == atom.id && l.rel == "#{CLASSIFIER_NAMESPACE}/negative-example"}
            0.0
          end
        
          unless strength.nil?
            item = FeedItem.find_or_create_from_atom(e)
            tag.taggings.create(:feed_item => item, :user => tag.user, :strength => strength)
          end
        end
      end
      
      tag
    end
  end

  named_scope :public, :conditions => { :public => true }
  
  # Matches the given value against any of the listed attributes.
  named_scope :matching, lambda { |q|
    conditions = %w[tags.name tags.description users.login].map do |attribute|
      "#{attribute} LIKE :q"
    end.join(" OR ")
    { :joins => :user, :conditions => [conditions, { :q => "%#{q}%" }] }
  }
  
  # Finds tags to which the user has subscribed or which the user has excluded from the Items view. Used to
  # scope results in +Tag.search+.
  named_scope :for, lambda { |user|
    joins = [
      "LEFT JOIN tag_subscriptions ON tags.id = tag_subscriptions.tag_id AND tag_subscriptions.user_id = :user_id",
      "LEFT JOIN tag_exclusions ON tags.id = tag_exclusions.tag_id AND tag_exclusions.user_id = :user_id"
    ]
      
    { :joins => sanitize_sql([joins.join(" "), { :user_id => user.id }]), 
      :conditions => ["(tags.user_id = ? OR tag_subscriptions.id IS NOT NULL OR tag_exclusions.id IS NOT NULL)", user.id]
    }
  }
  
  # Orders the results by the given order and direction. If no order is given or one is given but
  # is not one of the known orders, the default order is used. Likewise for direction.
  named_scope :by, lambda { |order, direction|
    orders = {
      "id"               => "tags.id",
      "name"             => "tags.sort_name",
      "public"           => "tags.public",
      "login"            => "users.login",
      "state"            => "state",
      "comments_count"   => "comments_count",
      "positive_count"   => "positive_count",
      "negative_count"   => "negative_count",
      "last_classified"  => "last_classified_at",
      "last_trained"     => "last_trained",
      "classifier_count" => "(feed_items_count - positive_count - negative_count)"
    }
    orders.default = "tags.sort_name"
    
    directions = {
      "asc" => "ASC",
      "desc" => "DESC"
    }
    directions.default = "ASC"
    
    { :joins => :user, :order => [orders[order.to_s], directions[direction.to_s]].join(" ") }
  }

  # The +search+ method adds a number of custom attributes to the SELECT
  # statement to avoid a bunch of additional queries. The attributes that
  # are preloaded are geared to supporting what is needed to render the 
  # public/private list of tags.
  def self.search(options = {})
    select = ['tags.*', 
              'users.login AS user_login',
              '(SELECT COUNT(*) FROM comments WHERE comments.tag_id = tags.id) AS comments_count',
              '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 1) AS positive_count',
              '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 0) AS negative_count', 
              '(SELECT COUNT(DISTINCT(feed_item_id)) FROM taggings WHERE taggings.tag_id = tags.id) AS feed_items_count',
              '(SELECT MAX(taggings.created_on) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0) AS last_trained',
              "CASE " <<
                "WHEN EXISTS(SELECT 1 FROM tag_subscriptions WHERE tags.id = tag_subscriptions.tag_id AND tag_subscriptions.user_id = #{options[:user].id}) THEN 0 " <<
                "WHEN EXISTS(SELECT 1 FROM tag_exclusions WHERE tags.id = tag_exclusions.tag_id AND tag_exclusions.user_id = #{options[:user].id}) THEN 1 " <<
                "ELSE 2 END AS state"]
    
    scope = by(options[:order], options[:direction])
    scope = scope.matching(options[:text_filter]) unless options[:text_filter].blank?
    scope = scope.for(options[:user]) if options[:own]
    
    scope.all(
      :select => select.join(","), :joins => :user,
      :group => "tags.id", :limit => options[:limit], :offset => options[:offset]
    )
  end
  
  def user_login
    read_attribute(:user_login) || user.login
  end

  def inspect
    "<Tag name=#{name}, user=#{user.login}>"
  end

private
  # The sort_name should remove non-alphanumeric and downcase the title.
  def set_sort_name
    self.sort_name = name.to_s.downcase.gsub(/^(a|an|the) /, '').gsub(/[^a-zA-Z0-9]/, '')
  end

  def notify_subscriptions_of_name_change
    if name_change
      self.tag_subscriptions.each do |tag_subscription|
        tag_subscription.tag_renamed(self.name_was, name)
      end
    end
  end

  # It used to be that when a public tag was made private all subscribers would lose access to it,
  # without notification. With the creation of the public tag archive account which receives
  # a copy of a deleted tag and moves existing subscriptions to that copy, the behavior of deleting existing
  # subscriptions when a public tag is made private is removed, as otherwise subscribers may become
  # distributed among multiple copies of the tag that are created in the archive account. There is a potential
  # privacy concern here, but since the tag was made public, anyone could have created a copy or exported it,
  # and our implementation of handling publication is necessarily imperfect unless we were to handle
  # publication by issuing successive static copies, preserving the historic relation of those copies, and
  # creating mechanisms by which users could rate versions and control which version they're using. Doing that is
  # beyond the present scope of this project and it is not not clear how easy it would be to create a UI that
  # a sufficient percentage of users would understand and utilize.
  #
  # def clear_subscriptions_unless_public
  #   self.tag_subscriptions.clear unless public?
  # end
  
  # Adds taggings for this tag from the taggings defined in the atom document.
  #
  # Each entry in the atom document defines a tagging from this tag to the
  # FeedItem identified by the entry's id.  The strength of the tagging
  # comes from the classifier:strength element in the category that matches
  # this tag in the entry. With these bits of information we can create a tagging.
  #
  # This needs to be fast so we'll bypass Active Record and do it directly in SQL.
  #
  def taggings_from_atom(atom)
    atom.entries.each do |entry|
      begin
        strength = if category = entry.categories.detect {|c| c.term == self.name && c.scheme =~ %r{/#{Regexp.escape(self.user.login)}/tags/$}}
          category[CLASSIFIER_NAMESPACE, 'strength'].first.to_f
        else 
          0.0
        end

        if strength >= 0.9
          connection.execute "INSERT IGNORE INTO taggings " +
                              "(feed_item_id, tag_id, user_id, classifier_tagging, strength, created_on) " +
                              "VALUES((select id from feed_items where uri = #{connection.quote(entry.id)})," + 
                              "#{self.id}, #{self.user_id}, 1, #{strength}, UTC_TIMESTAMP()) " +
                              "ON DUPLICATE KEY UPDATE strength = VALUES(strength);"
        end
      rescue URI::InvalidURIError => urie
        logger.warn "Invalid URI in Tag Assignment Document: #{entry.id}"
      rescue ActiveRecord::StatementInvalid => arsi
        logger.warn "Invalid taggings statement for #{entry.id}, probably the item doesn't exist."
      end
    end
    
    connection.execute("UPDATE tags SET last_classified_at = '#{Time.now.getutc.to_formatted_s(:db)}' where id = #{self.id}")
  end
end
