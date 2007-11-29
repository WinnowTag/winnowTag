require File.join(File.dirname(__FILE__), 'abstract_unit')

# Simulate setup/teardown in test_helper.rb
class Test::Unit::TestCase
  setup do
    @block_setup_in_parent = true
  end
  
  def setup
    @method_setup_in_parent = true
  end
  
  teardown do
    @block_teardown_in_parent = true
  end
  
  def teardown
    @method_teardown_in_parent = true
  end
end

# Simulate setup/teardown in test files
class OneTest < Test::Unit::TestCase
  setup do
    # Parent's setup should have already run
    assert @block_setup_in_parent
    assert @method_setup_in_parent
    
    @one = "One"
  end
  
  def teardown
    # Parent's teardown should have already run
    assert @block_teardown_in_parent
    assert @method_teardown_in_parent
  end
  
  def setup
  end
  
  def test_setup_in_parent
    assert @block_setup_in_parent
    assert @method_setup_in_parent
  end
  
  def test_one
    assert_equal "One", @one
  end
  
  def test_size
    assert_equal 4, _setup_blocks.size
    assert_equal 3, _teardown_blocks.size
  end
  
  def test_not_shared
    assert_nil @two
  end
end

class TwoTest < Test::Unit::TestCase
  def setup
    @two = "Two"
  end
  
  teardown do
    assert_equal "Two", @two
    @two = nil
  end
  
  # Check execution order, @two should be nil from above block
  def teardown
    assert_nil @two
  end
  
  def test_size
    assert_equal 3, _setup_blocks.size
    assert_equal 4, _teardown_blocks.size
  end
  
  def test_not_shared
    assert_nil @one
  end
end
