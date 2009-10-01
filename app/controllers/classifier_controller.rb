# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# Controller for the user's classifier.
#
# Each user only has a single classifier so this is a Singleton Resource.
#
# TODO: This could do with some refactoring.
#
# == Non-CRUD actions include:
#
# <tt>classify</tt>:: Starts a background classification process for the classifier.
# <tt>status</tt>: Gets JSON object containing the classification progress.
class ClassifierController < ApplicationController
  class ClassificationStartException < StandardError
    attr_reader :code
    
    def initialize(msg, code)
      super(msg)
      @code = code
    end
  end

  # Starts a classification job for the user.
  #
  # Errors are reported via 500 errors with JSON error messages.
  #
  # puct - Stands for Potentially Undertrained Changed Tags - because who wants to write that more than once?
  def classify
    respond_to do |format|
      begin
        start_classification_job
        format.json { render :nothing => true }
      rescue ClassificationStartException => detail
        format.json { render :json => detail.message.to_json, :status => detail.code }
      rescue ActiveResource::TimeoutError => te
        logger.fatal("Classifier timed out")
        logger.fatal(te.backtrace.join("\n"))
        ExceptionNotifier.deliver_exception_notification(te, self, request, {})
        format.json { render :json => 'Timeout contacting the classifier. Please try again later.'.to_json, :status => 500 }
      rescue => detail       
        logger.fatal(detail) 
        logger.fatal(detail.backtrace.join("\n"))
        format.json { render :json => I18n.t("winnow.notifications.classifier.could_not_be_started").to_json, :status => 500 }
      end
    end
  end
  
  # Gets the status of all the classification jobs running for the user.
  # This is resturned as a progress value between 0 and 100.
  #
  def status
    respond_to do |wants|
      status = {:error_message => t("winnow.notifications.classifier.not_running"), :progress => 100}
      
      session[:classification_job_id] && session[:classification_job_id].dup.each_with_index do |job_id, index|
        if job = Remote::ClassifierJob.find(job_id)
          # This combines the progress of all pending jobs 
          
          status = { :progress => ((status[:progress] * index) + job.progress).to_f / (index + 1),
                     :status   => h(job.status) }
                   
          if job.status == Remote::ClassifierJob::Status::ERROR
            status = {:error_message => h(job.error_message), :progress => 100}
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
          render :json => status[:error_message].to_json, :status => 500
        else
          render :json => status.to_json
        end
      end
    end
  end
  
private
  # Starts an actual classification job.
  #
  # This starts classification jobs for each of the user's changed tags if 
  # they don't already have a classification job running. 
  #
  # If any of the user's tags are potentially_undertrained a message 
  # telling them so is presented, asking them if they want to continue 
  # anyway. If they confirm, this sets puct_confirm to true so next time
  # we just create the classification jobs.
  #
  # Classififation job ids are stored in an array in the session.
  #
  def start_classification_job
    if job_running?
      raise ClassificationStartException.new(t("winnow.notifications.classifier.already_running"), 500)
    elsif params[:puct_confirm].blank? && !(puct = current_user.potentially_undertrained_changed_tags).empty?
      tag_names = puct.map { |tag| h(tag.name) }.to_sentence
      message = "You are about to classify " + tag_names + " which #{puct.size > 1 ? 'have' : 'has'} less than 6 positive examples. " <<
                "This might not work as well as you would expect.\nDo you want to proceed anyway?"
      raise ClassificationStartException.new(message, 412)
    elsif current_user.changed_tags.empty?
      raise ClassificationStartException.new(t("winnow.notifications.classifier.tags_not_changed"), 500)
    else
      session[:classification_job_id] = []
      current_user.changed_tags.each do |tag|
        tag_url = training_tag_url(tag, :format => 'atom')
        job = Remote::ClassifierJob.create(:tag_url => tag_url)
        session[:classification_job_id] << job.id
      end
    end
  end
  
  # Checks to see if a job is running.
  #
  # Goes through all classification job ids and checks if any of them
  # are still running.
  #
  def job_running?
    if session[:classification_job_id] && job_id = session[:classification_job_id].first
      begin
        job = Remote::ClassifierJob.find(job_id)
        if [Remote::ClassifierJob::Status::COMPLETE, Remote::ClassifierJob::Status::ERROR].include?(job.status)
          job.destroy
          false
        else
          true
        end
      rescue ActiveResource::ResourceNotFound => ex
        return false
      end
    end
  end
end
