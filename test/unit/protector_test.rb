# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'

class ProtectorTest < Test::Unit::TestCase
  def test_can_create_protector
    assert_valid Protector.create(:protector_id => 1)
  end
  
  def test_can_only_create_one_protector
    Protector.create(:protector_id => 1)
    assert_invalid(Protector.create(:protector_id => 2))
  end
  
  def test_get_protector_id_returns_id
    Protector.create(:protector_id => 1)
    assert_equal(1, Protector.id)
  end
  
  def test_get_protector_fetches_protector_from_collector
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
  
  def test_get_protector_creates_protector_if_it_doesnt_exist
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
