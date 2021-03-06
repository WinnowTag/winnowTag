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

require File.dirname(__FILE__) + '/../spec_helper'

describe ClassifierController do
  before(:each) do
    @user = Generate.user!
    login_as @user
    User.stub!(:find_by_id).and_return(@user)
    @user.stub!(:potentially_undertrained_changed_tags).and_return([])
    @user.stub!(:changed_tags).and_return([mock_model(Tag, :id => 99, :name => 'tag')])
  end  

  describe '#classify' do
    it "should create a new job on classify" do
      mock_job = mock_model(Remote::ClassifierJob)
      mock_job.stub!(:id)
      Remote::ClassifierJob.should_receive(:create).with(:tag_url => "http://test.host/tags/99/training.atom").and_return(mock_job)
    
      post "classify"
      response.should be_success
    end
  
    it "should store job id in the session" do
      mock_job = mock_model(Remote::ClassifierJob)
      mock_job.stub!(:id).and_return("MOCK-JOB-ID")
      Remote::ClassifierJob.should_receive(:create).with(:tag_url => "http://test.host/tags/99/training.atom").and_return(mock_job)
    
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
      response.body.should == "Tag '#{tag.name}' has less than 6 positive examples. It may be best to tag more positive examples first.\nDo you want to 'Run winnowTagger' anyway?".to_json
    end
    
    it "should start a job when changed tags are potentially undertrained and the user has confirmed" do
      @user.should_not_receive(:potentially_undertrained_changed_tags)
      
      mock_job = mock_model(Remote::ClassifierJob)
      mock_job.stub!(:id)
      Remote::ClassifierJob.should_receive(:create).with(:tag_url => "http://test.host/tags/99/training.atom").and_return(mock_job)
      
      post 'classify', :puct_confirm => '1'
    end
    
    it "should start a job when a stored job id is dead" do
      Remote::ClassifierJob.should_receive(:find).with("EXISTING-JOB-ID").once.and_raise(ActiveResource::ResourceNotFound.new(nil, nil))
      Remote::ClassifierJob.should_receive(:create).and_return(mock_model(Remote::ClassifierJob, :id => "NEWJOB"))
      session[:classification_job_id] = ["EXISTING-JOB-ID"]
      post "classify"
      response.should be_success
    end
  
    it "should remove the old job and start a new job when the stored job id is complete" do
      job = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::COMPLETE)
      job.should_receive(:destroy)
      Remote::ClassifierJob.should_receive(:find).with("EXISTING-JOB-ID").and_return(job)
      Remote::ClassifierJob.should_receive(:create).and_return(mock_model(Remote::ClassifierJob, :id => "NEWJOB"))
      session[:classification_job_id] = ["EXISTING-JOB-ID"]
      post "classify"
      response.should be_success
    end
    
    it "should remove the old job and start a new job when the stored job id is in error" do
      job = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::ERROR)
      job.should_receive(:destroy)
      Remote::ClassifierJob.should_receive(:find).with("EXISTING-JOB-ID").and_return(job)
      Remote::ClassifierJob.should_receive(:create).and_return(mock_model(Remote::ClassifierJob, :id => "NEWJOB"))
      session[:classification_job_id] = ["EXISTING-JOB-ID"]
      post "classify"
      response.should be_success
    end
    
    it "should start multiple jobs for multiple changed tags" do
      @user.stub!(:changed_tags).and_return([mock_model(Tag, :id => 90, :name => 'tag1'), mock_model(Tag, :id => 91, :name => 'tag2')])
      Remote::ClassifierJob.should_receive(:create).
                            with(:tag_url => "http://test.host/tags/90/training.atom").
                            and_return(mock_model(Remote::ClassifierJob, :id => 'JOB-1'))
      Remote::ClassifierJob.should_receive(:create).
                            with(:tag_url => "http://test.host/tags/91/training.atom").
                            and_return(mock_model(Remote::ClassifierJob, :id => 'JOB-2'))
                          
     post "classify"
     response.should be_success
     session[:classification_job_id].should == ['JOB-1', 'JOB-2']
    end
    
    it "should handle ActiveResource::Timeout errors" do
      mock_job = mock_model(Remote::ClassifierJob)
      mock_job.stub!(:id)
      Remote::ClassifierJob.should_receive(:create).
                            with(:tag_url => "http://test.host/tags/99/training.atom").
                            and_raise(ActiveResource::TimeoutError.new('classifier-timeout'))
      ExceptionNotifier.should_receive(:deliver_exception_notification)
      post "classify"
      response.code.should == "500"
      response.body.should == '"Communication with winnowTagger failed. It\'s OK to click \'Run winnowTagger\' again at any time."'
    end
  end
  
  describe '#status' do
    it "should return the status" do
      job = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::WAITING, :progress => 0)
      Remote::ClassifierJob.should_receive(:find).with("JOB-ID").and_return(job)
      session[:classification_job_id] = ["JOB-ID"]
      get "status"
      response.should be_success
      response.headers['X-JSON'].should include('"progress":0')
      response.headers['X-JSON'].should include('"status":"Waiting"')
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
      response.headers['X-JSON'].should include('"winnowTagger is not running."')
    end
    
    it "should combine the progress for multiple classification jobs" do
      job1 = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::WAITING, :progress => 75)
      job2 = mock_model(Remote::ClassifierJob, :status => Remote::ClassifierJob::Status::WAITING, :progress => 25)
      Remote::ClassifierJob.should_receive(:find).with("JOB-1").and_return(job1)
      Remote::ClassifierJob.should_receive(:find).with("JOB-2").and_return(job2)
      session[:classification_job_id] = ["JOB-1", "JOB-2"]      
      
      get "status"
      response.should be_success
      response.headers['X-JSON'].should include('"progress":50.0')
    end
  end
end
