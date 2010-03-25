# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# Represents a user of the system.
#
# Handles authentication via the ActsAsAuthenticated plugin and 
# authorization via the authorization plugin.
class User < ActiveRecord::Base
  acts_as_authorized_user
  acts_as_authorizable
  
  has_many :messages, :order => "created_at DESC"
  has_many :comments
  has_many :tags, :dependent => :delete_all
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
  has_many :feed_exclusions, :dependent => :delete_all
  has_many :excluded_feeds, :through => :feed_exclusions, :source => :feed
  has_many :tag_exclusions, :dependent => :delete_all
  has_many :excluded_tags, :through => :tag_exclusions, :source => :tag
  
  # for email address regex, see: http://www.regular-expressions.info/email.html
  validates_format_of :email, :with => /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
 
  # See the definition of this method below to learn about this callbacks
  before_save :update_prototype
 
  def globally_excluded?(tag_or_feed)
    if tag_or_feed.is_a?(Tag)
      excluded_tags(:load).include?(tag_or_feed)
    elsif tag_or_feed.is_a?(Feed)
      excluded_feeds(:load).include?(tag_or_feed)
    end
  end

  def subscribed?(tag)
    if tag.is_a?(Tag)
      subscribed_tags(:load).include?(tag)
    else
      raise ArgumentError, "subscribed only takes a tag"
    end
  end
  
  # Matches the given value against any of the listed attributes.
  named_scope :matching, lambda { |q|
    conditions = %w[users.login users.email users.firstname users.lastname].map do |attribute|
      "#{attribute} LIKE :q"
    end.join(" OR ")
    { :conditions => [conditions, { :q => "%#{q}%" }] }
  }
  
  # Orders the results by the given order and direction. If no order is given or one is given but
  # is not one of the known orders, the default order is used. Likewise for direction.
  named_scope :by, lambda { |order, direction|
    orders = {
      "id"               => "users.id",
      "login"            => "users.login",
      "email"            => "users.email",
      "logged_in_at"     => "users.logged_in_at",
      "last_accessed_at" => "users.last_accessed_at",
      "name"             => %w[users.lastname users.firstname users.login],
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
      "MAX(taggings.created_on) as last_tagging_on",
      "COUNT(DISTINCT(tags.id)) as tag_count"      
    ]
    
    scope = by(options[:order], options[:direction])
    scope = scope.matching(options[:text_filter]) unless options[:text_filter].blank?
    scope.all(
      :select => select.join(", "),
      :joins => "left outer join tags on users.id = tags.user_id " +
                "left outer join taggings on tags.id = taggings.tag_id and taggings.classifier_tagging = 0",
      :group => "users.id",
      :limit => options[:limit], 
      :offset => options[:offset]
    )
  end

  def last_tagging_on
    Time.parse(read_attribute(:last_tagging_on).to_s)
  end
  
  def changed_tags
    self.tags.find(:all, :conditions => ['updated_on > last_classified_at or last_classified_at is NULL'])
  end
  
  def potentially_undertrained_changed_tags
    self.changed_tags.select {|t| t.potentially_undertrained? }
  end

  def tags_for_sidebar
    Tag.find :all, 
      :select => ['tags.*',
                  '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 1) AS positive_count',
                  '(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.classifier_tagging = 0 AND taggings.strength = 0) AS negative_count', 
                  '(SELECT COUNT(DISTINCT(feed_item_id)) FROM taggings WHERE taggings.tag_id = tags.id) AS feed_items_count'
                 ].join(","),
      :conditions => ["tags.id IN (?) OR (tags.id IN(?) AND (tags.public = ? OR tags.user_id = ?))", 
                     tag_ids + subscribed_tag_ids - excluded_tag_ids, tag_ids.to_s.split(","), true, self],
      :order => "tags.sort_name"
  end

  def full_name
    "#{self.firstname} #{self.lastname}"
  end
  
  def email_address_with_name
    if firstname && lastname
      "\"#{full_name}\" <#{email}>"
    else
      email
    end
  end
  
  def email=(value)
    regex = /"?(\w+) ([^"]+)"? <(.+)>/i
    if md = regex.match(value)
      self[:email] = md[3]
      self.firstname = md[1] if self.firstname.blank?
      self.lastname = md[2] if self.lastname.blank?
    else
      self[:email] = value
    end
  end
  
  # Creating a user from the prototype will copy over the prototype's
  # feed subscriptions, tag subscriptions, tags, and taggings. This method will 
  # also activate the user and mark all system messages as read.
  def self.create_from_prototype(attributes = {})
    user = new(attributes)
    user.activate

    # Mark all existing message as read
    Message.read_by!(user)
    
    if prototype = User.find_by_prototype(true)
      prototype.tag_subscriptions.each do |tag_subscription| 
        user.tag_subscriptions.create! :tag_id => tag_subscription.tag_id
      end
      
      prototype.tags.each do |tag|
        new_tag = user.tags.create! :name => tag.name, :public => tag.public, :bias => tag.bias, :description => tag.description

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
  attr_accessor :password, :current_password

  validates_format_of :login, :with => /^[a-zA-Z0-9_-]+$/
  validates_presence_of :email, :time_zone
  validates_length_of :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,             :if => :password_required?
  validates_uniqueness_of :login, :email, :case_sensitive => false
  validate :current_password_matches, :if => :password_required?

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
    update_attributes!(:activated_at => Time.now.utc, :activation_code => nil)
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
    self.reminder_code = ActiveSupport::SecureRandom.hex(20)
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
    unless active?
      self.activation_code = ActiveSupport::SecureRandom.hex(20)
    end
  end
  
  def make_owner_of_self
    self.has_role('owner', self)
  end
  
  # If this user is the prototype, make sure to remove the prototype flag from all other users.
  def update_prototype
    if prototype?
      conditions = id ? ["id != ?", id] : nil
      User.update_all(["prototype = ?", false], conditions)
    end
  end

  def current_password_matches
    if crypted_password.present? and not authenticated?(current_password)
      errors.add(:current_password, "is not correct")
    end
  end
end
