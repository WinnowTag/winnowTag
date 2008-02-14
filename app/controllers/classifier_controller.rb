# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# Controller for the user's classifier.
#
# Each user only has a single classifier so this is a Singleton Resource.
#
# == Non-CRUD actions include:
#
# <tt>classify</tt>:: Starts a background classification process for the classifier.
# <tt>status</tt>: Gets JSON object containing the classification progress.
# <tt>cancel</tt>: Cancels the in progress classification.
#
class ClassifierController < ApplicationController
  class ClassificationStartException < StandardError
    attr_reader :code
    def initialize(msg, code)
      super(msg)
      @code = code
    end
  end
  
  # puct - Stands for Potentially Undertrained Changed Tags - because who wants to write that more than once?
  def classify
    respond_to do |wants|
      begin
        if job_running?
          raise ClassificationStartException.new("The classifier is already running.", 500)
        elsif params[:puct_confirm].blank? && !(puct = current_user.potentially_undertrained_changed_tags).empty?
          raise ClassificationStartException.new(puct.map{|t| t.name}.to_json, 412)
        elsif current_user.changed_tags.empty?
          raise ClassificationStartException.new("There are no changes to your tags", 500)
        else
          job = Remote::ClassifierJob.create(:user_id => current_user.id)          
          session[:classification_job_id] = job.id
        end
        
        wants.js   { render :nothing => true }
      rescue ClassificationStartException => detail
        wants.js   { render :json => detail.message, :status => detail.code }
      rescue => detail       
        logger.fatal(detail) 
        logger.debug(detail.backtrace.join("\n"))
        wants.js   { render :json => detail.message, :status => 500 }
      end
    end    
  end
  
  def status
    respond_to do |wants|
      status = {:error_message => 'No classification process running', :progress => 100}
      
      if (job_id = session[:classification_job_id]) && (job = Remote::ClassifierJob.find(job_id))
        status = {:progress => job.progress, :status => job.status}
        
        if job.status == Remote::ClassifierJob::Status::COMPLETE
          job.destroy
        end
      end
      
      wants.json do
        headers['X-JSON'] = status.to_json
        
        if status[:error_message]
          render :json => status[:error_message], :status => 500
        else
          render :json => status.to_json
        end
      end
    end
  end
  
  def cancel
    if (job_id = session[:classification_job_id]) && (job = Remote::ClassifierJob.find(job_id))
      job.destroy
      session[:classification_job_id] = nil
    end
    
    render :nothing => true
  end
  
  private
  def job_running?
    if job_id = session[:classification_job_id]
      begin
        job = Remote::ClassifierJob.find(job_id)
        return job.status != Remote::ClassifierJob::Status::COMPLETE
      rescue ActiveResource::ResourceNotFound => ex
        return false
      end
    end
  end
end
