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
  
  def test_admin_required
    cannot_access(:quentin, :get, :show)
  end
  
  def test_index_displays_protector_info
    get :show
    assert_instance_of(Remote::Protector, assigns(:protector))
    assert_response :success
  end
  
  def test_rebuild_calls_rebuild_on_protector_and_redirects_to_show
    Remote::ProtectedItem.should_receive(:rebuild)
    post :rebuild
    assert_redirected_to item_protection_path
  end

  # TODO: Needs to be moved to a view test
  # def test_cant_fetch_protector_should_display_error
  #   ActiveResource::HttpMock.respond_to do |mock|
  #     mock.get "/protectors/1.xml", {}, nil, 500
  #   end
  #   get :show
  #   assert_response :not_found
  #   assert_select "div#error", "Unable to fetch protection status from the collector"
  # end
end
