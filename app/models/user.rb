# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class User < ActiveRecord::Base   
  acts_as_authorized_user
  acts_as_authorizable
  
  has_many :messages, :order => "created_at DESC"
  has_many :feedbacks
  has_many :comments
  has_many :tags, :dependent => :delete_all
  has_many :sidebar_tags, :class_name => "Tag", :conditions => "show_in_sidebar = true"
  has_many :taggings, :dependent => :delete_all do
    def find_by_feed_item(feed_item, type = :all, options = {})
      with_scope(:find => {:conditions => ['taggings.feed_item_id = ?', feed_item.id]}) do
        find(type, options)
      end
    end

    def find_by_tag(tag, type = :all, options = {})
      with_scope(:find => {:conditions => ['taggings.tag_id = ?', tag.id]}) do
        find(type, options)
      end
    end
  end
  has_many :manual_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', false]
  has_many :classifier_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', true]
  has_many :deleted_taggings, :dependent => :delete_all
  has_many :tag_subscriptions, :dependent => :delete_all
  has_many :subscribed_tags, :through => :tag_subscriptions, :source => :tag
  has_many :feed_subscriptions, :dependent => :delete_all
  has_many :subscribed_feeds, :through => :feed_subscriptions, :source => :feed
  has_many :feed_exclusions, :dependent => :delete_all
  has_many :excluded_feeds, :through => :feed_exclusions, :source => :feed
  has_many :tag_exclusions, :dependent => :delete_all
  has_many :excluded_tags, :through => :tag_exclusions, :source => :tag
  has_many :folders, :dependent => :delete_all, :order => "position"
 
  before_save :update_prototype
 
  def feeds
    (subscribed_feeds - excluded_feeds).sort_by { |feed| feed.title.downcase.to_s }
  end
  
  def feed_ids
    subscribed_feed_ids - excluded_feed_ids
  end
 
  def globally_excluded?(tag_or_feed)
    if tag_or_feed.is_a?(Tag)
      excluded_tags.each { |t| } # force the association to load, so we don't do a separate query for each time this is called
      excluded_tags.include?(tag_or_feed)
    elsif tag_or_feed.is_a?(Feed)
      excluded_feeds.each { |f| } # force the association to load, so we don't do a separate query for each time this is called
      excluded_feeds.include?(tag_or_feed)
    end
  end

  def subscribed?(tag_or_feed)
    if tag_or_feed.is_a?(Tag)
      subscribed_tags.each { |t| } # force the association to load, so we don't do a separate query for each time this is called
      subscribed_tags.include?(tag_or_feed)
    elsif tag_or_feed.is_a?(Feed)
      subscribed_feeds.each { |f| } # force the association to load, so we don't do a separate query for each time this is called
      subscribed_feeds.include?(tag_or_feed)
    end
  end
  
  named_scope :matching, lambda { |q|
    conditions = %w[users.login users.email users.firstname users.lastname].map do |attribute|
      "#{attribute} LIKE :q"
    end.join(" OR ")
    { :conditions => [conditions, { :q => "%#{q}%" }] }
  }
  
  named_scope :by, lambda { |order, direction|
    orders = {
      "id"               => "users.id",
      "login"            => "users.login",
      "email"            => "users.email",
      "logged_in_at"     => "users.logged_in_at",
      "last_accessed_at" => "users.last_accessed_at",
      "name"             => %w[users.lastname users.firstname],
      "last_tagging_on"  => "last_tagging_on", # depends on select from search
      "tag_count"        => "tag_count"        # depends on select from search
    }
    orders.default = "users.login"
    
    directions = {
      "asc" => "ASC",
      "desc" => "DESC"
    }
    directions.default = "ASC"

    { :order => Array(orders[order]).map { |o| [o, directions[direction]].join(" ") }.join(", ") }
  }

  def self.search(options = {})
    select = [
      "users.*",
      "(SELECT MAX(taggings.created_on) FROM taggings USE INDEX (index_taggings_on_user_id_and_classifier_tagging) WHERE taggings.user_id = users.id AND taggings.classifier_tagging = false) AS last_tagging_on",
      "(SELECT COUNT(*) FROM tags WHERE tags.user_id = users.id) AS tag_count"
    ]
    
    scope = by(options[:order], options[:direction])
    scope = scope.matching(options[:text_filter]) unless options[:text_filter].blank?
    scope.all(
      :select => select.join(", "),
      :limit => options[:limit], :offset => options[:offset]
    )
  end

  def last_tagging_on
    Time.parse(read_attribute(:last_tagging_on).to_s)
  end
  
  # Updates any feed state between this feed and the user.
  #
  # Only makes changes if the feed is a duplicate
  def update_feed_state(feed)
    if feed.duplicate_id
      if feed_subscriptions.update_all(["feed_id = ?", feed.duplicate_id], ["feed_id = ?", feed.id]) > 0
        subscribed_feeds.reload
      end
    end
  end
  
  def changed_tags
    self.tags.find(:all, :conditions => ['updated_on > last_classified_at or last_classified_at is NULL'])
  end
  
  def potentially_undertrained_changed_tags
    self.changed_tags.select {|t| t.potentially_undertrained? }
  end

  def tags_for_sidebar(tag_ids)
    Tag.find :all, 
      :select => ['tags.*',
                  '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 1) AS positive_count',
                  '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 0) AS negative_count', 
                  '(SELECT COUNT(DISTINCT(feed_item_id)) FROM taggings WHERE taggings.tag_id = tags.id) AS feed_items_count'
                 ].join(","),
      :conditions => ["tags.id IN (?) OR (tags.id IN(?) AND (tags.public = ? OR tags.user_id = ?))", 
                      sidebar_tag_ids + subscribed_tag_ids - excluded_tag_ids, tag_ids.to_s.split(","), true, self],
      :order => "tags.name"
  end

  def full_name
    "#{self.firstname} #{self.lastname}"
  end
  
  def self.create_from_prototype(attributes = {})
    user = new(attributes)
    user.save!
    user.activate
    # Mark all existing message as read
    Message.read_by!(user)
    
    if prototype = User.find_by_prototype(true)
      prototype.folders.each do |folder| 
        user.folders.create! :name => folder.name, :tag_ids => folder.tag_ids, :feed_ids => folder.feed_ids
      end
      
      prototype.feed_subscriptions.each do |feed_subscription| 
        user.feed_subscriptions.create! :feed_id => feed_subscription.feed_id
      end
      
      prototype.tag_subscriptions.each do |tag_subscription| 
        user.tag_subscriptions.create! :tag_id => tag_subscription.tag_id
      end
      
      prototype.tags.each do |tag|
        new_tag = user.tags.create! :name => tag.name, :public => tag.public, :bias => tag.bias, :show_in_sidebar => tag.show_in_sidebar, :comment => tag.comment

        tag.taggings.each do |tagging|
          user.taggings.create! :classifier_tagging => tagging.classifier_tagging, :strength => tagging.strength, :feed_item_id => tagging.feed_item_id, :tag_id => new_tag.id
        end
      end
    end
    
    user
  rescue ActiveRecord::RecordInvalid
    user
  end

  # Code Generated by Acts_as_authenticated
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_format_of :login, :with => /^[a-zA-Z0-9_-]+$/
  validates_presence_of :email, :time_zone
  validates_length_of :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_uniqueness_of :login, :email, :case_sensitive => false

  before_create :make_activation_code
  after_create :make_owner_of_self
  before_save :encrypt_password

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find :first, :conditions => ['login = ? AND activated_at IS NOT NULL', login]
    u && u.authenticated?(password) ? u : nil
  end

  def self.encrypt(password)
    BCrypt::Password.create(password)
  end

  def encrypt(password)
    self.class.encrypt(password)
  end

  def authenticated?(password)
    BCrypt::Password.new(crypted_password) == password
  rescue BCrypt::Errors::InvalidHash
    false
  end
  
  # Activates the user in the database.
  def activate
    update_attributes(:activated_at => Time.now.utc, :activation_code => nil)
  end
  
  def active?
    activated_at && activated_at < Time.now
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  def to_param
    self.login
  end
  
  def enable_reminder!
    @automated = true
    self.reminder_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    self.reminder_expires_at = 1.day.from_now
    save!
  end
  
  def login!(time = Time.now)
    @automated = true
    self.logged_in_at = time
    self.save!
  end
  
  def reminder_login!(time = Time.now)
    @automated = true
    self.logged_in_at = time
    self.reminder_code = nil
    self.reminder_expires_at = nil
    self.save!
  end
  
protected
  def encrypt_password
    return if password.blank?
    self.crypted_password = encrypt(password)
  end
  
  def password_required?
    !automated? && (crypted_password.blank? || password?)
  end
  
  def automated?
    @automated
  end
  
  def password?
    !password.blank?
  end
  
  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
  def make_owner_of_self
    self.has_role('owner', self)
  end
  
  def update_prototype
    if prototype?
      User.update_all(["prototype = ?", false])
    end
  end
end
