# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
require File.dirname(__FILE__) + '/../spec_helper'

class ProtectorTest < Test::Unit::TestCase
  before(:each) do
    Protector.delete_all
  end
  
  it "can_create_protector" do
    Protector.new(:protector_id => 1).should be_valid
  end
  
  it "can_only_create_one_protector" do
    Protector.create(:protector_id => 1)
    Protector.create(:protector_id => 2).should_not be_valid
  end
  
  it "get_protector_id_returns_id" do
    Protector.create(:protector_id => 1)
    assert_equal(1, Protector.id)
  end
  
  it "get_protector_fetches_protector_from_collector" do
    Protector.create(:protector_id => 1)
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/protectors/1.xml", {}, {:id => 1, :name => 'protector', :protected_items_count => 10}.to_xml(:root => 'protector')
    end
    
    protector = Protector.protector
    assert_instance_of(Remote::Protector, protector)
    assert_equal('protector', protector.name)
    assert_equal(10, protector.protected_items_count)
    assert_equal(1, protector.id)
  end
  
  it "get_protector_creates_protector_if_it_doesnt_exist" do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post "/protectors.xml", {}, nil, 201, 'Location' => '/protectors/2.xml'
      mock.get  "/protectors/2.xml", {}, {:id => 2, :name => 'http://test.com/', :protected_items_count => 10}.to_xml(:root => 'protector')
    end
    
    protector = Protector.protector('http://test.com/')
    assert_equal(2, protector.id.to_i)
    assert_equal('http://test.com/', protector.name)
    assert_equal(2, Protector.id)
  end
end
