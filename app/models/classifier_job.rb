# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ClassifierJob < ActiveRecord::Base
  attr_accessor :classifier_args
  after_create  :start_job
  
  def active?
    if self.complete? || self.failed?
      false
    else
      !MiddleMan[self.jobkey].nil? rescue false
    end
  end
  
  def set_classifying_message(tags = nil)
    tag_text = Array(tags).empty? ? 'all' : Array(tags).join(", ")    
    update_attributes(:progress_title   => "Classifying #{tag_text}", 
                      :progress_message => "Classifying #{tag_text}")
  end
  
  def cancel!
    if wkr = worker
      wkr.cancel!
    end
    
    update_attributes(:complete => true,
                      :progress_title => "Cancelled",
                      :progress_message => "Cancelled")
  end
  
  private
  def worker
    MiddleMan.worker(self.jobkey) rescue nil
  end

  def start_job
    begin
      self.jobkey = MiddleMan.new_worker(:class => :classification_worker,
                                          :args => classifier_args)
      self.save!
      self
    rescue Exception => e
      logger.fatal(e)
      raise StandardError, "Unable to start the classification process. The BackgroundRB process may be down."
    end    
  end
end
