# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'tag'
require 'feed_item_tokenizer'

#
# Provides the hook between Winnow and the Bayes classifier.
#
# The BayesClassifier class sets up and manages an instance of the Bayes classifier
# that can be trained with a user's taggings and will classify FeedItem instances
# into the Tag categories defined by a user.
#
#
# == Training
#
# The BayesClassifier will train the classifier on taggings created by it's user. Taggings
# with a strength of 1 are treated as positive examples and taggings with a strength of
# 0 are treated as negative examples. When a tagging is delete by the user, the classifier
# is untrained on that tagging.
#
# For the most part, training is achieved by calling the update_training method which will
# update the training data to be consistent with the current state of the user's taggings.
#
# Training Methods are:
#
# * update_training
# * retrain
# * clear_training_data
# * train_random_background
# * random_background_uptodate?
# * train
# * untrain
#
# == Classification
#
# Classification currently work by running items through the Bayes.guess method of the classifier.
# When the scores produced by the classifier are above the insertion cutoff, a Tagging is created
# for the Tag on that FeedItem with the strength of the tagging set to the score produced by the
# classifier.
#
# Classification Methods are:
#
# * BayesClassifier.classify_new_items
# * guess
# * classify
# * classify_all
# * classify_new_items
#
# == Random Backgrounds
#
# BayesClassifier will instantiate the Bayes instance will a non-classified background pool
# of self.random_background_size items randomly selected from the available items.  This provides
# a starting base for the classifier.
#
# == Background Processing
#
# BayesClassifier supports starting classification processes in the background using BackgroundRB.
#
# Methods dealing with background processes are:
#
# * start_background_classification
# * classification_in_progress
# * classifier_progress
#
# == Bias Settings
#
# The Bayes classifier supports bias settings on a per tag basis. To capture this BayesClassifier
# stores a default_bias as a float and a Hash of bias values with tag names as keys. This allows
# a user to set a overall default bias and to override that default per tag.
#
# The methods to support this functionality are:
#
# * bias
# * bias=
# * default_bias=
# * bias_without_defaults
#
#
# == Schema Information
# Schema version: 57
#
# Table name: bayes_classifiers
#
#  id                     :integer(11)   not null, primary key
#  version                :string(255)   default("1"), not null
#  created_on             :datetime      
#  updated_on             :datetime      
#  last_executed          :datetime      
#  deleted_at             :datetime      
#  mode                   :string(255)   
#  tagger_id              :integer(11)   
#  tagger_type            :string(255)
#  positive_cutoff        :float         default(0.9)
#  insertion_cutoff       :float         default(0.8)
#  random_background_size :integer(11)   default(400)
#  jobkey                 :string(255)   
#  borderline_threshold   :float         default(0.02)
#  default_bias           :float         default(1.0)
#  bias                   :text          
#

class BayesClassifier < ActiveRecord::Base
  class ClassifierAlreadyRunning < StandardError; end #:nodoc:
  class RegressionTestFailure < StandardError; end #:nodoc:
  # Pattern used for negative training pools for a given Tag
  NEGATIVE_POOL_PATTERN = '_!not_#{pool_name}' unless const_defined?(:NEGATIVE_POOL_PATTERN)
  # Pool name for the Random background.
  RANDOM_BACKGROUND = "__random_background__" unless const_defined?(:RANDOM_BACKGROUND)
  # List of tag names that will not be classified.
  #  
  # * Background tags are tags that provide a background to the other tags but will not be classified themselves. 
  # * Pools created for negative training will not be classified.
  # * Tags starting with * will not be classified.
  #
  NON_CLASSIFIED_TAGS = ['seen', 'duplicate', 'missing entry', RANDOM_BACKGROUND, 'SHORT', /^\*.*/, /^_!not_.*/] unless const_defined?(:NON_CLASSIFIED_TAGS)
   
  acts_as_paranoid
  acts_as_authorizable
  belongs_to :user
  has_one :classifier_data, :order => 'updated_on DESC', :dependent => :destroy
  has_one :classifier_execution, :order => 'created_on DESC', :dependent => :destroy
  has_one :classifier_job, :dependent => :nullify
  serialize :bias
  validates_numericality_of :random_background_size, :only_integer => true, :message => "is not an integer"
  validates_numericality_of :default_bias, :positive_cutoff, :insertion_cutoff, :borderline_threshold
  after_destroy {|classifier| classifier.user.classifier_taggings.clear }
  
  # Deletes any classifier taggings which have been orphaned.  
  #
  # Classifier taggings are orphaned when their taggable has been
  # archived.  We can just delete these taggings.
  #
  def self.delete_orphaned_taggings
    Tagging.delete_all(["classifier_tagging = 1 and feed_item_id not in (select id from feed_items)"])
  end
  
  # Returns a list of tags that were changed since the last time
  # this classifier was executed.
  def changed_tags
    if last_executed
      tags = self.user.taggings.find(:all, 
              :conditions => ['taggings.created_on > ? ', last_executed],
              :include => :tag,
              :group   => 'tag_id').
            map(&:tag) +
      self.user.deleted_taggings.find(:all,
              :conditions => ['deleted_taggings.deleted_at > ?', last_executed],
              :include => :tag,
              :group => 'tag_id').
            map(&:tag)
      tags.uniq
    else
      self.user.tags
    end
  end
  
  # ---------------------------------------------  
  # Training methods
  # ---------------------------------------------
  
  # Updates the train data for the classifier to be consistent with
  # the Tagging state for the user. 
  #
  # This first ensures that the random background is uptodate, if not retrain is called.
  # If the random background is uptodate, we untrain all Taggings deleted since the time
  # the classifier was trained and train on all the Taggings created since.
  # 
  def update_training
    self.classifier # Make sure the classifier is loaded
    if self.random_background_uptodate?
      self.class.benchmark("Training new taggings", Logger::DEBUG, false) do
        self.user.deleted_taggings.find(:all, 
                                  :conditions => ['deleted_at >= ?',
                                    self.classifier_data.updated_on]). each do |tagging|
          self.untrain(tagging)
        end
      
        conditions = ['created_on > ?', self.classifier_data.updated_on] unless self.classifier_data.data.nil?
        self.user.taggings.find(:all, :conditions => conditions).each do |tagging|
          self.train(tagging)
        end
      end
    else
      self.retrain(false)
    end
    self.class.silence{self.save!}
  end
  
  # Retrains the classifier on all taggings and the designated random background.
  # 
  # First deletes the existing training data, then trains on all users taggings and
  # finally creates the random background.
  #
  def retrain(do_save = true)
    logger.info "Starting Retraining..."
    self.clear_training_data
    
    self.class.benchmark("Training on #{self.user}'s taggings", Logger::DEBUG, false) do
      user.taggings.each do |tagging|
        self.train(tagging)
      end
    end
    
    self.class.benchmark("Training random background of #{self.random_background_size} items", Logger::DEBUG, false) do
      self.train_random_background
    end
    
    self.class.silence {self.save if do_save}
  end
  
  # Clears all the training data stored by the classifier. 
  #
  # After calling this method you will have a blank classifier.
  #
  def clear_training_data
    if self.classifier_data
      self.classifier_data.data = nil
      self.classifier_data.save
      initialize_classifier
    end
  end
    
  # Trains the classifier with a random sample of background items.  This can be used
  # to bootstrap the classifier with a reasonable sized background.
  #
  # If the random background is already trained this can be quite an expensive call since
  # it will need to untrain all the random background items before training an new random
  # background, so you should only call this if random_background_uptodate? returns false.
  #
  def train_random_background   
    if self.classifier.pools[RANDOM_BACKGROUND]
      # untrain existing random background
      self.classifier.pools[RANDOM_BACKGROUND].trained_uids.keys.each do |uid|
        if uid =~ /::([\d]+)$/
          self.classifier.untrain(RANDOM_BACKGROUND, FeedItem.find($1), uid)
        end
      end
    end

    FeedItem.find_random_items_with_tokens(self.random_background_size).each do |item|
      self.classifier.train(RANDOM_BACKGROUND, item, item.uid)
    end
  end

  # Checks that the random background is uptodate.
  #
  # We assume the random background is uptodate if the number of items in the random
  # background is equal to random_background_size.
  #
  def random_background_uptodate?
    self.classifier.pools[RANDOM_BACKGROUND] != nil and 
      self.classifier.pools[RANDOM_BACKGROUND].train_count == self.random_background_size
  end
  
  # Trains the classifier with a tagging
  #
  # Taggings are only trained if they are user's taggings.
  #
  # If the strength of the tagging is 0 it is treated as 
  # a negative tagging and the pool produced by passing
  # the tag name through the NEGATIVE_POOL_PATTERN is trained.
  #
  def train(tagging, feed_item = tagging.feed_item)
    begin
      if feed_item
        logger.debug { "Training #{tagging.tag.name} with #{tagging.feed_item.uid}" }
        self.classifier.train(get_pool_name(tagging), feed_item, feed_item.uid)
      end
    rescue ArgumentError => ae
      logger.warn ae.message
    end
  end
  
  # Untrains the classifier for a given tagging.
  #
  # Taggings are only untrained if they are user taggings.
  #
  # If the strength of the tagging is 0 it is treated as 
  # a negative tagging and the pool produced by passing
  # the tag name through the NEGATIVE_POOL_PATTERN is trained.
  #
  def untrain(tagging)
    begin
      logger.debug { "Untraining #{tagging.tag.name} with #{tagging.feed_item.uid}" }
      self.classifier.untrain(get_pool_name(tagging), tagging.feed_item, tagging.feed_item.uid)
    rescue ArgumentError => ae
      logger.warn ae.message
    end
  end
    
  
  
  def trained_for?(tag)
    self.classifier.pool_names.include?(tag.name)
  end
  
  # -----------------------------------------------------------------
  # Classification methods
  # -----------------------------------------------------------------
 
  # This does the classification without creating anything in the DB.
  # 
  # It returns the tag_strength in a hash for each tag on which the classifier is trained.
  # 
  # 
  def guess(taggable, options = {})
    self.classifier.guess(taggable, options)
  end
  
  # Classifys new items for all the classifiers in the system.
  #
  # This will iterate through all classifiers calling their classify_new_items method.
  #
  def self.classify_new_items
    self.find(:all).each do |c|
      if c.user.nil?
        c.destroy
      else
        begin          
          benchmark("Classified new items for user:#{c.user.to_s}", Logger::DEBUG, false) do
            c.classify_new_items
          end
        rescue
          logger.warn "Classification failed for #{c.user.to_s}: #{$!.message}"
        end
      end
    end
  end
  
  # Classifys each item that has been added since this classifier was last run.
  #
  def classify_new_items
    return 0 if user.tags.empty? # bail out if there are no tags
    conditions = ['feed_items.created_on >= ?', self.last_executed] unless self.last_executed.nil?
    options = self.create_classifier_execution
    total = 0
    FeedItem.find(:all, :select => 'feed_items.id, feed_items.position, fitc.tokens as tokens',
                        :joins => "left join feed_item_tokens_containers as fitc on feed_items.id = fitc.feed_item_id" +
                                  " and fitc.tokenizer_version = #{FeedItemTokenizer::VERSION}",
                        :conditions => conditions).each_with_index do |item, index|
      total = index
      self.classify(item, options)
    end
       
    self.last_executed = Time.now.utc
    self.save
    total
  end
  
  # Classifys all items using this classifier.
  #
  # This iterates through all the items in the database and calls classify for each of them. Classification
  # is carried out using the current settings of the classifier.
  #
  # There are a couple of optimization worth noting here:
  #
  # * Firstly, the each_with_index method added to ActiveRecord::Base is used to iterate through
  #   the items.  This prevent us from having to load all the items in the memory at once.
  # * Second, we perform a join on the feed_items and feed_items_tokens_containers tables,
  #   selecting out the tokens column into the same record as the feed items. This prevents having
  #   to fetch the tokens in another DB query and having to us Rails eager loading which is too
  #   costly over so many items.
  # * Finally, we use the Bayes#with_guess_options method to passing the classification options
  #   once to prevent a parse and object creation for every call to Bayes#guess.
  #
  # === Parameters
  #
  # Takes an optional options Hash containing:
  # 
  # <tt>:save</tt> <em>(true|false)</em>:: If true, the classifier will be saved after classification. Default is false.
  # <tt>:limit</tt>:: Limits the number of items that are classified.
  # <tt>:only</tt>:: A list of tags to classify.  If empty all tags will be classified.
  #   
  # === Yields
  #
  # This will yield the item and it's index for each item classified. This is to support things like
  # progress reporting. A block can also call break to cancel in progress classification, note that
  # classification does not take place within a transaction, so any items already classified and tagged
  # will keep their classifier generated taggings.  
  #
  def classify_all(options = {})
    logger.info "Starting classification"
    do_save = options.delete(:save)
    limit = options.delete(:limit)
    ce = self.create_classifier_execution(options)    
    
    self.class.benchmark("Total classification time", Logger::DEBUG, false) do
      self.classifier.with_guess_options(ce.classification_options) do |classifier|
          # Do a manual join between the feed_items and feed_item_tokens_containers tables
          # and read the tokens straight from the feed_items model.  This is much faster
          # than doing an eager load using :include (about an order of magnitude) and since
          # we call this alot during classification we want it to be as fast as possible.
          select = 'feed_items.id, feed_items.position, fitc.tokens as tokens'
          joins = "left join feed_item_tokens_containers as fitc on feed_items.id = fitc.feed_item_id" +
                  " and fitc.tokenizer_version = #{FeedItemTokenizer::VERSION}"
          FeedItem.each_with_index(:select => select, :joins => joins, :limit => limit, :column => :position) do |item, index|
            classify(item, ce, nil, classifier)
            yield(item, index) if block_given?
          end      
      end 
    end 
    self.last_executed = Time.now.utc
    self.class.silence {self.save unless do_save == false}
  end
  
  # Classify a single item inserting taggings with a probability higher than insertion_cutoff into the DB.
  #
  # This method will work properly just using the default parameters for all arguments after <tt>taggable</tt>.
  # The remaining arguments are there to support optimizations during bulk classification via classify_all.
  #
  # === Parameters
  #
  # <tt>feed_item</tt>:: The item to classify.
  # <tt>classifier_execution</tt>:: 
  #    The metadata for the classifier execution process. This will be attached
  #    to each saved Tagging via its Tagging#metadata attribute.
  # <tt>options</tt>:: 
  #    A Hash of classifier options. This can also be <tt>:from_metadata</tt> in which case the
  #    classifier options are retrieved from a call to <tt>classifier_execution.classification_options</tt>.
  # <tt>+classifier+</tt>:: 
  #    The Bayes classifier to use. This is primarly provided to support the Bayes#guess_with_options optimization.
  #
  def classify(feed_item, classifier_execution = self.create_classifier_execution, options = :from_metadata, classifier = self.classifier)
    options = classifier_execution.classification_options if options == :from_metadata
    classifications = classifier.guess(feed_item, options)
    
    # collect the classifications which match the users tags and are above the cutoff
    tagging_rows = classification_tags.map do |(tag_id, tag_name)|
      if score = classifications[tag_name] and score >= classifier_execution.insertion_cutoff        
        logger.info("Score on #{feed_item.dom_id} for #{tag_name}, strength = #{score}")
        
          "(UTC_TIMESTAMP()," +                                          # created_on 
          " #{self.user_id}," +                                      # The user
          " #{feed_item.id}," +                                     # The feed item
          " #{tag_id},"  +                                          # The tag id
          " #{score},"   +                                          # The probability score
          "'#{classifier_execution.class.name}'," +                 # Store the execution details as metadata
          " #{classifier_execution.id}," +
          " 1)"
      end
    end.compact
              
    # do the insertion directly for performance - this might be a bit MySQL specific with the NOW()
    unless tagging_rows.empty?
      sql = "INSERT INTO taggings ("            +
              "`created_on`,"                   +
              "`user_id`,"                      +
              "`feed_item_id`,"                 +
              "`tag_id`,"                       +
              "`strength`,"                     +
              "`metadata_type`, `metadata_id`," +
              "`classifier_tagging`) VALUES " +
              "#{tagging_rows.join(',')}"    
      self.class.silence{connection.insert(sql)}
    end
  end
  
  def self.regression_test(error_limit = 0.000001)
    if user = User.find_by_login('regression_tester')
      user.classifier.regression_test(error_limit)
    end
  end
  
  # Does a regression test against a classifier.
  #
  # If the RMSE is greater than the error_limit a RegressTestFailure error is thrown.
  #
  def regression_test(error_limit = 0.000001)
    taggings_by_id = user.classifier_taggings.find(:all, :include => :tag).inject({}) do |h,t|
      h[t.feed_item_id] ||= []
      h[t.feed_item_id] = (h[t.feed_item_id] << t)
      h
    end
    
    errors = []
    options = self.classification_options
    FeedItem.find(taggings_by_id.keys, :include => :latest_tokens).each do |fi|
      scores = self.guess(fi, options)      
      taggings_by_id[fi.id].each do |tagging|
        error = scores[tagging.tag.name] - tagging.strength
        errors << (error ** 2)
      end
    end
    
    error = Math.sqrt(errors.inject() {|s, e| s + e } / errors.size)
    
    if error > error_limit
      raise RegressionTestFailure, "RMSE of #{error} was greater than expected error of #{error_limit}"
    end
    
    true
  end
  
  #---------------------------------------------------------------
  # Methods dealing with background process for classification
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
  # Starts a background classification process using BackgroundRB.
  #
  # This allows long running classification processes to run in the background.
  # It requires an active BackgroundRB server to be running with the settings
  # defined in <tt>RAILS_ROOT/config/backgroundrb.yml</tt>.
  #
  # Currently this just starts a ClassificationWorker bound to this classifier,
  # which will in turn call classify_all. This will also call clear_existing_taggings
  # before starting the process.
  #
  # The jobkey of the new worker process will be stored in the jobkey attribute of self
  # and the worker object can later the be retrieved by calling classification_in_progress. 
  # 
  # === Raises
  # 
  # <tt>ClassifierAlreadyRunning</tt>::
  #   This is raised if there is a classification process already running for this classifier.
  #   In this case you can get a reference to the worker by calling classification_in_progress.
  # <tt>StandardError</tt>::
  #   This is raised if there is a problem starting up the classification worker, e.g. the
  #   BackgroundRB server is down.
  #
  def start_background_classification
    if self.classifier_job && self.classifier_job.active?
      raise ClassifierAlreadyRunning, "The classifier is already running."
    end
    
    clear_existing_taggings(self.changed_tags)
    create_classifier_job(:classifier_args => {
                              :classifier => self.id
                          })
  end
  
  # Returns the current active job or nil if there is none
  #
  def current_job
    self.classifier_job if self.classifier_job and self.classifier_job.active?
  end
  
  # Returns the progress of the current job if there is one, or 0 otherwise.
  #
  def progress
    if job = current_job
      job.progress
    else
      0
    end
  end
  
  # Returns the progress title of the current job or nil
  #
  def progress_title
    if job = current_job
      job.progress_title
    end
  end
    
  # Clears all taggings created by the classifier.
  #
  # This will bypass the acts_as_paranoid nature of Tagging and just delete
  # the taggings directly.
  #
  # === Parameters
  #
  # <tt>tag_list</tt>::
  #   A list of tags to delete taggings for.
  #
  def clear_existing_taggings(tag_list)
    tags = Array(tag_list).compact
    unless tags.empty?
      Tagging.delete_all(["user_id = ? and classifier_tagging = ? and tag_id in (?)",
                          self.user, true, tags.map {|tag| Tag(self.user, tag).id }])
    end
  end
  
  # The names of attributes which are classification options.
  CLASSIFICATION_OPTION_KEYS = [:default_bias, :bias, :random_background_size,
                    :positive_cutoff, :insertion_cutoff] unless const_defined?(:CLASSIFICATION_OPTION_KEYS)
  
  # Returns a Hash of all the attributes that are used as classification options.
  def classification_options
    returning(self.attributes.symbolize_keys) do |options|
      options.delete_if do |key, value|
        not (CLASSIFICATION_OPTION_KEYS.include?(key))
      end
    
      if options[:bias]
        options[:bias].default = self.default_bias
      end
    end
  end
  
  #--
  # Methods to deal with per tag bias
  #++
  
  # Merges the current bias hash with a new set of values from another hash.
  #
  # This allows a caller to set the bias for a tag using Hash syntax without
  # overwriting existing biases for other tags.  For example you can do:
  #
  #   bayes_classifier.bias
  #   => {'tag1' => 1.1, 'tag2' => 1.2}
  #   bayes_classifier.bias = {'tag1' => 1.3}
  #   => {'tag1' => 1.3, 'tag2' => 1.2}
  #
  # To support a single value for default biases using the default_bias attribute
  # you can set the bias for a tag to 'default' and the hash entry for the tag will
  # be cleared. For example:
  #
  #   bayes_classifier.bias
  #   => {'tag1' => 1.1, 'tag2' => 1.2}
  #   bayes_classifier.bias = {'tag1' => 'default'}
  #   => {'tag2' => 1.2}
  #  
  # This will allow the default_bias value to come through when you next retreive the
  # bias value for 'tag1'.
  #
  def bias=(bias_hash)
    initial_bias = (read_attribute(:bias) or {})
    
    new_bias = bias_hash.inject({}) do |hash, (tag, bias)|
      if bias == "default"
        initial_bias.delete(tag)
      else
        hash[tag] = bias.to_f unless bias.nil? or bias == ""
      end
      hash
    end
    write_attribute(:bias, initial_bias.merge(new_bias))
  end

  # Sets the default bias.
  #
  # This writes the default_bias attribute as well as sets the default for the bias hash.
  #
  def default_bias=(value)
    write_attribute(:default_bias, value)
    self.bias = {} if self.bias.nil?
    self.bias.default = value
  end
  
  # Retrieves the bias Hash with the hash's default set to default_bias so any tags
  # without a overriding bias in the Hash will get the default bias. For example:
  #
  #   bayes_classifier.default_bias = 1.0
  #   bayes_classifier.bias
  #   => {'tag1' => 1.3, 'tag2' => 1.1}
  #   bayes_classifier.bias['tag3']
  #   => 1.0
  #
  def bias
    bias = read_attribute(:bias)
    if bias.nil?
      bias = self.bias = {}
    end
    bias.default = default_bias
    bias
  end
  
  # Gets the bias has without the defaults set. This is so you can easily tell
  # which tags don't have a bias override because the hash will return nil for 
  # this tags. For example:
  #
  #   bayes_classifier.default_bias = 1.0
  #   bayes_classifier.bias_without_defaults
  #   => {'tag1' => 1.3, 'tag2' => 1.1}
  #   bayes_classifier.bias['tag3']
  #   => nil
  #
  def bias_without_defaults
    bias_without_defaults = bias.dup
    bias_without_defaults.default = nil
    bias_without_defaults
  end
    
# Methods for inspecting classifier internals

  # Gets a handle to the underlying classifier which will be an instance of Bayes.
  def classifier
    if @classifier.nil?
      initialize_classifier
    end
    
    @classifier
  end
  
  # Returns the tokens used by the classifier
   def tokens
     self.classifier.foreground_union.tokens.keys
   end

   # Returns the number of items a tag has been trained for
   def train_count(tag)
     self.classifier.train_count(tag.name)
   end

   # Gets the number of tokens in a tags training pool
   def token_count(tag)
     if self.classifier.pools[tag.name]
       self.classifier.pools[tag.name].token_count
     end
   end

   # Get the number of unique tokens in a tags training pool
   def unique_token_count(tag)
     if self.classifier.pools[tag.name]
       self.classifier.pools[tag.name].tokens.size
     end
   end
  
  protected
  def after_save
    if @classifier
      if self.classifier_data.nil?
        self.classifier_data = ClassifierData.new
      end
      self.classifier_data.data = self.classifier.dump
      self.classifier_data.save!
    end
  end
  
  private 
  def initialize_classifier(classifier_data = self.classifier_data) 
    @classifier = Bayes::Classifier.load((classifier_data.data if classifier_data)) do |bayes|
      bayes.tokenizer = FeedItemTokenizer.new
      bayes.pools_to_ignore = NON_CLASSIFIED_TAGS
      bayes.background_pool_specs << Bayes::Classifier::PoolSpec.new do |spec|
        spec.name = "Negative Taggings"
        spec.description = "Pool to store user applied negative taggings"
        spec.pattern = NEGATIVE_POOL_PATTERN
      end
      bayes.background_pool_specs << Bayes::Classifier::PoolSpec.new do |spec|
        spec.name = "Random Background"
        spec.pattern = RANDOM_BACKGROUND
      end    
    end
  end
  
  # Get the pool name for a tagging.
  #
  # This will be the classifier pool that the tagging is used
  # to train.  For positive taggings it is just the tag name,
  # for negative taggings is the tag name passed through the
  # NEGATIVE_POOL_PATTERN.
  #
  def get_pool_name(tagging)
    pool_name = tagging.tag.name
    if tagging.strength == 0
      pool_name = eval("\"#{NEGATIVE_POOL_PATTERN}\"")
    end
    
    pool_name
  end
  
  # Cache the user's tags for classifier execution speed
  def classification_tags
    unless @classification_tags
      @classification_tags = user.tags.map {|tag| [tag.id, tag.name]}
    end

    @classification_tags
  end
end
