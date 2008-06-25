# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe ItemProtectionController do
  fixtures :users

  before(:each) do
    login_as(:admin)
    Protector.create(:protector_id => 1)
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/protectors/1.xml", {}, {:id => 1, :name => 'protector', 
                                         :protected_items_count => 10, 
                                         :created_on => Time.now,
                                         :updated_on => Time.now }.to_xml(:root => 'protector')
    end
  end
  
  it "admin_required" do
    cannot_access(:quentin, :get, :show)
  end
  
  it "index_displays_protector_info" do
    get :show
    assert_response :success
    assert_instance_of(Remote::Protector, assigns(:protector))
  end
  
  it "rebuild_calls_rebuild_on_protector_and_redirects_to_show" do
    Remote::ProtectedItem.should_receive(:rebuild)
    post :rebuild
    assert_redirected_to item_protection_path
  end

  it "cant_fetch_protector_should_display_error" do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/protectors/1.xml", {}, nil, 500
    end
    get :show
    assert_response :not_found
    flash[:error].should == "Unable to fetch protection status from the collector"
  end
end
