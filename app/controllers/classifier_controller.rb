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
  def classify
    respond_to do |wants|
      begin
        changed_tags = current_user.changed_tags
        
        if job_running?
          raise "The classifier is already running."
        elsif changed_tags.empty?
          raise "There are no changes to your tags" 
        else
          changed_tags.each do |t|
            t.classifier_taggings.clear
          end
          job = Remote::ClassifierJob.create(:user_id => current_user.id)          
          session[:classification_job_id] = job.id
        end
        
        wants.js   { render :nothing => true }
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
