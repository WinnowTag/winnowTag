# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Controller for the user's classifier.
#
# Each user only has a single classifier so this is a Singleton Resource.
#
# == Non-CRUD actions include:
#
# <tt>classify</tt>:: Starts a background classification process for the classifier.
# <tt>status</tt>: Gets JSON object containing the classification progress.
# <tt>cancel</tt>: Cancels the in progress classification.
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
        start_classification_job        
        wants.json   { render :nothing => true }
      rescue ClassificationStartException => detail
        wants.json   { render :json => detail.message, :status => detail.code }
      rescue ActiveResource::TimeoutError => te
        logger.fatal("Classifier timed out")
        logger.fatal(te.backtrace.join("\n"))
        wants.json   { render :json => 'Timeout contacting the classifier. Please try again later.', :status => 500 }
        ExceptionNotifier.deliver_exception_notification(te, self, request, {})
      rescue => detail       
        logger.fatal(detail) 
        logger.fatal(detail.backtrace.join("\n"))
        wants.json   { render :json => detail.message, :status => 500 }
      end
    end    
  end
  
  def status
    respond_to do |wants|
      status = {:error_message => _(:classifier_not_running), :progress => 100}
      
      session[:classification_job_id] && session[:classification_job_id].dup.each_with_index do |job_id, index|
        if job = Remote::ClassifierJob.find(job_id)
          # This combines the progress of all pending jobs 
          
          status = { :progress => ((status[:progress] * index) + job.progress).to_f / (index + 1),
                     :status   => job.status }
                   
          if job.status == Remote::ClassifierJob::Status::ERROR
            status = {:error_message => job.error_message, :progress => 100}
            job.destroy
            session[:classification_job_id].delete(job_id)          
          elsif job.status == Remote::ClassifierJob::Status::COMPLETE
            job.destroy
            session[:classification_job_id].delete(job_id)
          end
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
    session[:classification_job_id] && session[:classification_job_id].each do |job_id|
      if job = Remote::ClassifierJob.find(job_id)
        job.destroy
      end
    end
    
    session[:classification_job_id] = nil
    
    render :nothing => true
  end
  
private
  def start_classification_job
    if job_running?
      raise ClassificationStartException.new(_(:classifier_running), 500)
    elsif params[:puct_confirm].blank? && !(puct = current_user.potentially_undertrained_changed_tags).empty?
      # TODO: sanitize
      raise ClassificationStartException.new(puct.map{|t| t.name}.to_json, 412)
    elsif current_user.changed_tags.empty?
      raise ClassificationStartException.new(_(:tags_not_changed), 500)
    else
      session[:classification_job_id] = []
      current_user.changed_tags.each do |tag|
        tag_url = url_for(:controller => 'tags', :action => 'training', 
                          :format => 'atom',     :user => current_user.login, 
                          :tag_name => tag.name)
        job = Remote::ClassifierJob.create(:tag_url => tag_url)
        session[:classification_job_id] << job.id
      end
    end
  end
  
  def job_running?
    if session[:classification_job_id] && job_id = session[:classification_job_id].first
      begin
        job = Remote::ClassifierJob.find(job_id)
        return job.status != Remote::ClassifierJob::Status::COMPLETE
      rescue ActiveResource::ResourceNotFound => ex
        return false
      end
    end
  end
end
