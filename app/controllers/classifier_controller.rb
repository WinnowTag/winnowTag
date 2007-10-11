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
# <tt>classification_status</tt>: Gets JSON object containing the classification progress.
# <tt>cancel_classification</tt>: Cancels the in progress classification.
#
class ClassifierController < ApplicationController
  before_filter :setup_classifier
  verify :only => [:classify, :clear, :reset], :method => :post, :render => SHOULD_BE_POST

  def show
    respond_to do |wants|
      wants.html {redirect_to :controller => 'tags'}
    end
  end
     
  def edit
    respond_to do |wants|
      wants.html {redirect_to :controller => 'tags'}
    end
  end
  
  def update
    if @classifier.update_attributes(params[:classifier])
      redirect_to :back
    else
      render :action => 'edit'
    end    
  end
  
  def classify
    respond_to do |wants|
      begin
        raise "There are no changes to your tags" if @classifier.changed_tags.empty?
        @classifier.start_background_classification
        wants.html { redirect_to :action => 'classification_status' }
        wants.js   { render :nothing => true }
      rescue => detail
        logger.fatal(detail)        
        wants.html { flash[:error] = detail.message; redirect_to :back }
        wants.js   { render :json => detail.message, :status => 500 }
      end
    end    
  end
  
  def status
    respond_to do |wants|
      status = {:error_message => 'No classification process running', :progress => 100}
      if job = @classifier.classifier_job
        if job.progress >= 100 || job.active?
          status = job.attributes
        end
      end
      
      wants.json do
        headers['X-JSON'] = status.to_json
        
        if status[:error_message]
          render :json => status[:error_message], :status => 500
        else
          render :nothing => true
        end
      end
    end
  end
  
  def cancel
    if process = @classifier.current_job
      process.cancel!
    end
    
    render :nothing => true
  end

  private
  def setup_classifier
    @classifier = current_user.classifier
  end
end
