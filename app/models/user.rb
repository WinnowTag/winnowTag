# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
# 

require 'digest/sha1'
require 'tzinfo'
 
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
  
# == Schema Information
# Schema version: 57
#
# Table name: users
#
#  id                        :integer(11)   not null, primary key
#  login                     :string(80)    default(""), not null
#  crypted_password          :string(40)    
#  email                     :string(60)    default(""), not null
#  firstname                 :string(40)    
#  lastname                  :string(40)    
#  salt                      :string(40)    default(""), not null
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
  acts_as_authorized_user
  acts_as_authorizable
  composed_of :tz, :class_name => TZInfo::Timezone, :mapping => %w(time_zone identifier)
  has_one :classifier, :class_name => "BayesClassifier"
  has_many :collection_job_results
  has_one :collection_job_result_to_display, :class_name => "CollectionJobResult", :foreign_key => 'user_id',
              :conditions => ['user_notified = ?', false], :order => 'collection_job_results.created_on asc', 
              :include => :feed
  has_many :tags
  has_many :taggings, :dependent => :delete_all, :extend => FindByFeedItem
  has_many :manual_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', false]
  has_many :classifier_taggings, :class_name => 'Tagging', :conditions => ['classifier_tagging = ?', true],
            :dependent => :delete_all
  has_many :deleted_taggings, :dependent => :delete_all
  has_many :tagging_tags, :through => :taggings, :select => 'DISTINCT tags.*', 
                :order => 'tags.name ASC', :source => :tag
  has_many :views do
    def default
      find_by_default(true)
    end
  end
  has_many :unread_items, :dependent => :delete_all
  before_create :create_classifier
  after_create :assign_manager_role_to_classifier
 
  def has_read_item?(feed_item_or_feed_item_id)
    !self.unread_items.exists?(['feed_item_id = ?', feed_item_or_feed_item_id])
  end
  
  def assign_manager_role_to_classifier
    self.has_role 'manager', self.classifier
  end
    
  # Tagging related methods
  
  # Gets a list of tags with a count of their usage for this user.
  #
  # This will be made of all tags the use currently has applied on items.
  #
  def tags_with_count(options = {})
    options.assert_valid_keys(:feed_filter, :text_filter)
    joins = []
    
    if options[:feed_filter]
      if !options[:feed_filter][:include].empty? or !options[:feed_filter][:exclude].empty?
        feed_joins = "INNER JOIN feed_items ON taggings.feed_item_id = feed_items.id"
      
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
      joins << " INNER JOIN feed_item_contents_full_text on taggings.feed_item_id = feed_item_contents_full_text.id" +
                  " and MATCH(content) AGAINST(#{connection.quote(options[:text_filter])} in boolean mode)"
    end

    tag_list = self.tagging_tags.find(:all, 
       :select => 'tags.*, ' +
                  'count(IF(classifier_tagging = 0 and taggings.strength = 1, 1, NULL)) as count, ' +
                  'count(IF(classifier_tagging = 0 and taggings.strength = 0, 1, NULL)) as negative_count, ' +
                  'count(IF(classifier_tagging = 1 and taggings.strength >= 0.9, 1, NULL)) as classifier_count',
       :joins => joins.join(' '),
       :group => 'tags.id',
       :order => 'tags.name ASC'
     )

    if options[:feed_filter] and !options[:feed_filter][:include].empty?
      # if feed was specified we need to fold it into the entire list of tags
      all_tags = self.tagging_tags.find(:all, :select => "distinct tags.name, tags.id, '0' as count")

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
    self.taggings.find(:first, :select => 'count(distinct feed_item_id) as count').count.to_i
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
           user_id = #{self.id}
         group by feed_item_id
       ) as counts;
      END_SQL
    ).first.average.to_f
  end
  
  # Code Generated by Acts_as_authenticated
  # Virtual attribute for the unencrypted password
  SALT = "Things which are unimportant can seem important. Things which are important can seem unimportant." unless const_defined?(:SALT)
  attr_accessor :password

  validates_presence_of     :login, :email, :firstname, :lastname, :time_zone
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
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

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    # made this the same as the LoginEngine encryption mechanism so pwd migrate
    pwdhash = Digest::SHA1.hexdigest("#{SALT}--#{password}--}")
    Digest::SHA1.hexdigest("#{SALT}--#{salt}#{pwdhash}--}")
  end

  def display_name
    "#{self.firstname} #{self.lastname}"
  end
  
  def to_s
    self.display_name
  end
  
  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  # Activates the user in the database.
  def activate
    @activated = true
    update_attributes(:activated_at => Time.now.utc, :activation_code => nil)
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
  
  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end
    
    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
    
    def make_owner_of_self
      self.has_role('owner', self)
    end
end
