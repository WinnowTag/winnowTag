# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
#
  
# == Schema Information
# Schema version: 57
#
# Table name: users
#
#  id                        :integer(11)   not null, primary key
#  login                     :string(80)    default(""), not null
#  crypted_password          :string(255)    
#  email                     :string(60)    default(""), not null
#  firstname                 :string(40)    
#  lastname                  :string(40)    
#  activation_code           :string(40)    
#  created_at                :datetime      
#  updated_at                :datetime      
#  logged_in_at              :datetime      
#  deleted_at                :datetime      
#  activated_at              :datetime      
#  remember_token            :string(255)   
#  remember_token_expires_at :datetime      
#  last_accessed_at          :datetime      
#  last_session_ended_at     :datetime      
#

class User < ActiveRecord::Base   
  module FindByFeedItem
    def find_by_feed_item(feed_item, type = :all, options = {})
      with_scope(:find => {:conditions => 
          ['taggings.feed_item_id = ?', feed_item.id]}) do
        find(type, options)
      end
    end

    def find_by_tag(tag, type = :all, options = {})
      with_scope(:find => {:conditions => ['taggings.tag_id = ?', tag.id]}) do
        find(type, options)
      end
    end
  end
  
  acts_as_authorized_user
  acts_as_authorizable
  composed_of :tz, :class_name => "TZInfo::Timezone", :mapping => %w(time_zone identifier)
  has_many :messages, :order => "created_at DESC"
  has_many :collection_job_results
  has_one :collection_job_result_to_display, :class_name => "CollectionJobResult", :foreign_key => 'user_id',
              :conditions => ['user_notified = ?', false], :order => 'collection_job_results.created_on asc', 
              :include => :feed
  has_many :tags, :dependent => :delete_all
  has_many :sidebar_tags, :class_name => "Tag", :conditions => "show_in_sidebar = true"
  has_many :taggings, :extend => FindByFeedItem, :dependent => :delete_all
  has_many :manual_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', false]
  has_many :classifier_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', true]
  has_many :deleted_taggings, :dependent => :delete_all
  has_many :read_items, :dependent => :delete_all do
    def for(feed)
      find(:all, :joins => :feed_item, :conditions => { "feed_items.feed_id" => feed })
    end
  end
  has_many :tag_subscriptions, :dependent => :delete_all
  has_many :subscribed_tags, :through => :tag_subscriptions, :source => :tag
  has_many :feed_subscriptions, :dependent => :delete_all
  has_many :subscribed_feeds, :through => :feed_subscriptions, :source => :feed
  has_many :feed_exclusions, :dependent => :delete_all
  has_many :excluded_feeds, :through => :feed_exclusions, :source => :feed
  has_many :tag_exclusions, :dependent => :delete_all
  has_many :excluded_tags, :through => :tag_exclusions, :source => :tag
  has_many :folders, :dependent => :delete_all
 
  before_save :update_prototype
 
  def feeds
    (subscribed_feeds - excluded_feeds).sort_by { |feed| feed.name.to_s }
  end
  
  def feed_ids
    subscribed_feed_ids - excluded_feed_ids
  end
 
  def subscribed?(tag_or_feed)
    if tag_or_feed.is_a?(Tag)
      subscribed_tags.include?(tag_or_feed)
    elsif tag_or_feed.is_a?(Feed)
      subscribed_feeds.include?(tag_or_feed)
    end
  end
  
  class << self
    def search(options = {})
      conditions, values = [], []
      
      unless options[:text_filter].blank?
        ored_conditions = []
        [:login, :email, :firstname, :lastname].each do |attribute|
          ored_conditions << "users.#{attribute} LIKE ?"
          values          << "%#{options[:text_filter]}%"
        end
        conditions << "(" + ored_conditions.join(" OR ") + ")"
      end
      
      order = case options[:order]
      when "login", "email", "logged_in_at", "last_accessed_at", "id"
        "users.#{options[:order]}"
      when "name"
        "lastname, firstname"
      when "last_tagging_on", "tag_count"
        options[:order]
      else
        "users.login"
      end
    
      options_for_find = { :conditions => conditions.blank? ? nil : [conditions.join(" AND "), *values] }
      
      results = find(:all, options_for_find.merge(
                     :select => "users.*, MAX(taggings.created_on) AS last_tagging_on, (SELECT count(*) FROM tags WHERE tags.user_id = users.id) AS tag_count", 
                     :joins => "LEFT JOIN taggings ON taggings.user_id = users.id AND taggings.classifier_tagging = false",
                     :order => order, :group => "users.id", :limit => options[:limit], :offset => options[:offset]))
      
      if options[:count]
        [results, count(options_for_find)]
      else
        results
      end
    end
  end
  
  # Gets the date the tagger last created a tagging.
  def last_tagging_on
    if last_tagging_on = read_attribute(:last_tagging_on)
      Time.parse(last_tagging_on)
    else
      last_tagging = self.manual_taggings.find(:first, :order => 'taggings.created_on DESC')
      last_tagging ? last_tagging.created_on : nil
    end
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
  
  def globally_excluded?(tag_or_feed)
    if tag_or_feed.is_a?(Tag)
      excluded_tags.include?(tag_or_feed)
    elsif tag_or_feed.is_a?(Feed)
      excluded_feeds.include?(tag_or_feed)
    end
  end

  def has_read_item?(feed_item)
    self.read_items.exists?(['feed_item_id = ?', feed_item])
  end
    
  # Gets the number of items tagged by this tagger
  def number_of_tagged_items
    self.taggings.find(:first, :select => 'count(distinct feed_item_id) as count').count.to_i
  end

  # Gets the percentage of items tagged by this tagger
  def tagging_percentage(klass = FeedItem)
    100 * number_of_tagged_items.to_f / klass.count
  end

  # Gets the average number of tags a user has applied to an item.
  def average_taggings_per_item
    Tagging.find_by_sql(<<-END_SQL
      select avg(count) as average from (
         select count(id) as count
         from taggings
         where
           user_id = #{self.id}
         group by feed_item_id
       ) as counts;
      END_SQL
    ).first.average.to_f
  end
  
  def changed_tags
    self.tags.find(:all, :conditions => ['updated_on > last_classified_at or last_classified_at is NULL'])
  end
  
  def potentially_undertrained_changed_tags
    self.changed_tags.select {|t| t.potentially_undertrained? }
  end
  
  # Code Generated by Acts_as_authenticated
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email, :time_zone
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  validates_inclusion_of    :time_zone, :in => TZInfo::Timezone.all_identifiers, :message => "is not a valid timezone"
  before_create :make_activation_code
  after_create :make_owner_of_self
  before_save :encrypt_password

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login]
    u && u.authenticated?(password) ? u : nil
  end

  def self.encrypt(password)
    BCrypt::Password.create(password)
  end

  def display_name
    "#{self.firstname} #{self.lastname}"
  end
  
  def to_s
    self.display_name
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
    @activated = true
    update_attributes(:activated_at => Time.now.utc, :activation_code => nil)
  end
  
  def active?
    activated_at && activated_at < Time.now
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
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
  
  def self.create_from_prototype(attributes = {})
    user = new(attributes)
    user.save!
    user.activate
    
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
  
protected
  # before filter 
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
