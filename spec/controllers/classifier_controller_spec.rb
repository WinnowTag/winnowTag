# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe ClassifierController do
  before(:each) do
    @user = Generate.user!
    login_as @user
    User.stub!(:find_by_id).and_return(@user)
    @user.stub!(:potentially_undertrained_changed_tags).and_return([])
    @user.stub!(:changed_tags).and_return([mock_model(Tag, :name => 'tag')])
  end  

  describe '#classify' do
    it "should create a new job on classify" do
      mock_job = mock_model(Remote::ClassifierJob)
      mock_job.stub!(:id)
      Remote::ClassifierJob.should_receive(:create).with(:tag_url => "http://test.host/#{@user.login}/tags/tag/training.atom").and_return(mock_job)
    
      post "classify"
      response.should be_success
    end
  
    it "should store job id in the session" do
      mock_job = mock_model(Remote::ClassifierJob)
      mock_job.stub!(:id).and_return("MOCK-JOB-ID")
      Remote::ClassifierJob.should_receive(:create).with(:tag_url => "http://test.host/#{@user.login}/tags/tag/training.atom").and_return(mock_job)
    
      post "classify"
      session[:classification_job_id].should == ["MOCK-JOB-ID"]
    end
  
    it "should not start a job when no tags have changed" do
      @user.should_receive(:changed_tags).and_return([])
      Remote::ClassifierJob.should_not_receive(:create)
      post "classify"
      session[:classification_job_id].should be_nil
      assert_response 500
    end
  
    it "should not start a job when one is already running" do
      job = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::WAITING)
      Remote::ClassifierJob.should_receive(:find).with("EXISTING-JOB-ID").and_return(job)
      Remote::ClassifierJob.should_not_receive(:create)
      session[:classification_job_id] = ["EXISTING-JOB-ID"]
      post "classify"
      assert_response 500
    end
  
    it "should not start a job when changed tags are potentially undertrained" do
      tag = mock_model(Tag, :name => "tag")
      @user.should_receive(:potentially_undertrained_changed_tags).and_return([tag])
      Remote::ClassifierJob.should_not_receive(:create)
      post 'classify'
      response.code.should == "412"
      response.body.should == "You are about to classify #{tag.name} which has less than 6 positive examples. This might not work as well as you would expect.\nDo you want to proceed anyway?".to_json
    end
    
    it "should start a job when changed tags are potentially undertrained and the user has confirmed" do
      @user.should_not_receive(:potentially_undertrained_changed_tags)
      
      mock_job = mock_model(Remote::ClassifierJob)
      mock_job.stub!(:id)
      Remote::ClassifierJob.should_receive(:create).with(:tag_url => "http://test.host/#{@user.login}/tags/tag/training.atom").and_return(mock_job)
      
      post 'classify', :puct_confirm => '1'
    end
    
    it "should start a job when a stored job id is dead" do
      Remote::ClassifierJob.should_receive(:find).with("EXISTING-JOB-ID").once.and_raise(ActiveResource::ResourceNotFound.new(nil, nil))
      Remote::ClassifierJob.should_receive(:create).and_return(mock_model(Remote::ClassifierJob, :id => "NEWJOB"))
      session[:classification_job_id] = ["EXISTING-JOB-ID"]
      post "classify"
      response.should be_success
    end
  
    it "should start a job when the stored job id is complete" do
      job = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::COMPLETE)
      Remote::ClassifierJob.should_receive(:find).with("EXISTING-JOB-ID").and_return(job)
      Remote::ClassifierJob.should_receive(:create).and_return(mock_model(Remote::ClassifierJob, :id => "NEWJOB"))
      session[:classification_job_id] = ["EXISTING-JOB-ID"]
      post "classify"
      response.should be_success
    end
    
    it "should start multiple jobs for multiple changed tags" do
      @user.stub!(:changed_tags).and_return([mock_model(Tag, :name => 'tag1'), mock_model(Tag, :name => 'tag2')])
      Remote::ClassifierJob.should_receive(:create).
                            with(:tag_url => "http://test.host/#{@user.login}/tags/tag1/training.atom").
                            and_return(mock_model(Remote::ClassifierJob, :id => 'JOB-1'))
      Remote::ClassifierJob.should_receive(:create).
                            with(:tag_url => "http://test.host/#{@user.login}/tags/tag2/training.atom").
                            and_return(mock_model(Remote::ClassifierJob, :id => 'JOB-2'))
                          
     post "classify"
     response.should be_success
     session[:classification_job_id].should == ['JOB-1', 'JOB-2']
    end
    
    it "should handle ActiveResource::Timeout errors" do
      mock_job = mock_model(Remote::ClassifierJob)
      mock_job.stub!(:id)
      Remote::ClassifierJob.should_receive(:create).
                            with(:tag_url => "http://test.host/#{@user.login}/tags/tag/training.atom").
                            and_raise(ActiveResource::TimeoutError.new('classifier-timeout'))
      ExceptionNotifier.should_receive(:deliver_exception_notification)
      post "classify"
      response.code.should == "500"
      response.body.should == '"Timeout contacting the classifier. Please try again later."'
    end
  end
  
  describe '#status' do
    it "should return the status" do
      job = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::WAITING, :progress => 0)
      Remote::ClassifierJob.should_receive(:find).with("JOB-ID").and_return(job)
      session[:classification_job_id] = ["JOB-ID"]
      get "status"
      response.should be_success
      response.headers['X-JSON'].should include('"progress": 0')
      response.headers['X-JSON'].should include('"status": "Waiting"')
    end

    it "should delete the job when complete" do
      job = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::COMPLETE, :progress => 100)    
      job.should_receive(:destroy)
      Remote::ClassifierJob.should_receive(:find).with("JOB-ID").and_return(job)
      session[:classification_job_id] = ["JOB-ID"]
      get "status"
      response.should be_success    
    end
    
    it "should delete the job when it errors" do
      job = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::ERROR, :error_message => 'blah', :progress => 0)
      job.should_receive(:destroy)
      Remote::ClassifierJob.should_receive(:find).with("JOB-ID").and_return(job)
      session[:classification_job_id] = ["JOB-ID"]
      get "status"
      response.code.should == "500"
    end
  
    it "should return an error when a stale job key is sent" do
      Remote::ClassifierJob.should_receive(:find).with("STALE").and_return(nil)
      session[:classification_job_id] = ["STALE"]
      get "status"
      assert_response 500
      response.headers['X-JSON'].should include('"error_message": "No classification process running"')
    end
    
    it "should combine the progress for multiple classification jobs" do
      job1 = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::WAITING, :progress => 75)
      job2 = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::WAITING, :progress => 25)
      Remote::ClassifierJob.should_receive(:find).with("JOB-1").and_return(job1)
      Remote::ClassifierJob.should_receive(:find).with("JOB-2").and_return(job2)
      session[:classification_job_id] = ["JOB-1", "JOB-2"]      
      
      get "status"
      response.should be_success
      response.headers['X-JSON'].should include('"progress": 50.0')      
    end
  end
  
  describe '#cancel' do
    it "should cancel a running job" do
      job = mock_model(Remote::ClassifierJob)
      job.should_receive(:destroy)
    
      Remote::ClassifierJob.should_receive(:find).with("JOB-ID").and_return(job)
      session[:classification_job_id] = ["JOB-ID"]
    
      post "cancel"
      session[:classification_job_id].should be_nil
    end
    
    it "should cancel all classification jobs" do
      job1 = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::WAITING, :progress => 75)
      job2 = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::WAITING, :progress => 25)
      job1.should_receive(:destroy)
      job2.should_receive(:destroy)
      Remote::ClassifierJob.should_receive(:find).with("JOB-1").and_return(job1)
      Remote::ClassifierJob.should_receive(:find).with("JOB-2").and_return(job2)
      session[:classification_job_id] = ["JOB-1", "JOB-2"]      
      
      post "cancel"
      session[:classification_job_id].should be_nil
    end
  end  
end
