# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ClassificationWorker < BackgrounDRb::Worker::RailsBase
  attr_accessor :logger
  class JobKeyMismatch < StandardError
    def initialize(worker_key, db_key)
      @worker_key, @db_key = worker_key, db_key
    end
  end
  
  def do_work(args)
    args.assert_valid_keys([:classifier, :limit])
    raise ArgumentError, "You must specify a Classifier id using the :classifier argument" if args[:classifier].nil?
    setup_logging

    begin
      progress = 0
      feed_item_count = [FeedItem.count, args[:limit]].compact.min
      progress_increment = 100.0 / feed_item_count
      classifier = BayesClassifier.find(args.delete(:classifier))
      job = classifier.classifier_job

      if self.jobkey != job.jobkey
       raise JobKeyMismatch.new(self.jobkey, job.jobkey) 
      end
    
      job.update_attributes(:progress_title => "Training", :progress_message => "Training")      
      classifier.update_training      
      job.set_classifying_message("changed tags")
      changed_tags = classifier.changed_tags.map(&:name)
      
      classifier.classify_all(args.merge(:only => changed_tags)) do |fi, index|
        # Only update the progress if we have gone up a whole number
        if progress.to_i < (progress += progress_increment).to_i
          job.update_attributes(:progress         => progress.to_i, 
                                :progress_message => progress_message(index, feed_item_count))
        end
        break if cancelled?
      end
    
      job.update_attributes(:complete         => true,
                            :progress         => 100,
                            :progress_title   => "Complete",
                            :progress_message => "Classification Complete")
    rescue JobKeyMismatch => jkme
      logger.fatal(jkme)
    rescue Exception => e
      logger.fatal(e)
      logger.fatal(e.backtrace.join("\n"))
      if job
        job.update_attributes(:complete      => true,
                              :failed        => true,
                              :error_message => e.message)
      end
    ensure
      self.delete
    end
  end
  
  def progress_message(index, total)
    "Classifying Item #{index + 1} of #{total}"
  end

  # Cancel the background process
  def cancel!
    @cancelled = true
  end
  
  def cancelled?
    @cancelled
  end
  
  private
  def setup_logging
    unless RAILS_ENV == "test"
      self.logger = Logger.new(File.join(RAILS_ROOT, 'log', 'classification.log'), "daily")
      self.logger.level = Logger::DEBUG
      BayesClassifier.logger = self.logger
    else
      self.logger = BayesClassifier.logger
    end
  end
end
ClassificationWorker.register unless RAILS_ENV == 'test'
