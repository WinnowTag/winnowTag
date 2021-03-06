# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


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
        format.json { render :json => I18n.t("winnow.notifications.classifier.timeout_contacting").to_json, :status => 500 }
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
      tag_names = puct.map { |tag| h(tag.name) }
      raise ClassificationStartException.new(t("winnow.notifications.classifier.confirm_few_positives", :tag_names => tag_names.to_sentence, :count => tag_names.length), 412)
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
