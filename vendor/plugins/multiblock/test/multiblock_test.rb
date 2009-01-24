require File.dirname(__FILE__) + '/test_helper'

require_relative "../src/multiblock"

class MultiblockTest < Test::Unit::TestCase
  
  def setup
    @target = Object.new
  end
  
  context ".[]" do
    should "be a way to create a multiblock with an expectation" do
      @target.instance_eval do
        def yielder
          yield Multiblock[:a, 12345]
        end
      end
      
      run_basic_test
    end
  end
  
  context ".new" do
    should "be a way to create a multiblock with an expectation" do
      @target.instance_eval do
        def yielder
          yield Multiblock.new(:a, 12345)
        end
      end
      
      run_basic_test
    end
  end
  
  context "#[]" do
    should "set up expectations" do
      @target.instance_eval do
        def yielder
          b = Multiblock.new
          yield b[:a, 12345]
        end
      end
      
      run_basic_test
    end
  end
  
  context "#method_missing" do
    setup do
      @target.instance_eval do
        def yielder do_bar=false
          b = Multiblock.new
          if do_bar
            yield b[:foo]
            yield b[:bar]
          else
            yield b[:foo]
          end
        end
      end
    end
    
    should "ignore extra blocks" do
      @target.yielder do |block|
        block.bollocks
      end
    end
    
    should "return the result of the first matching block" do
      called = [false, false]
      res = @target.yielder do |block|
        block.foo { called[0] = true; :goodness}
        block.foo { called[1] = true; :gracious}
      end
      assert_equal [true, false], called
      assert_equal :goodness, res
    end
    
    should "be reusable" do
      called = []
      @target.yielder(true) do |block|
        block.foo {called << :foo}
        block.bar {called << :bar}
      end
      assert_equal [:foo, :bar], called
    end
    
    should "catch everything in else" do
      saved = nil
      res = @target.yielder do |block|
        block.else {|*args| saved = args; :else}
      end
      assert_equal [:foo], saved
      assert_equal :else, res
    end
    
  end

  def run_basic_test
    yielded = nil
    yielder_return = @target.yielder do |result|
      result.a {|arg| 
        yielded = arg;
        :a
      }
      result.b {raise "got in b"}
      result.c {raise "got in c"}
    end
    
    assert_equal 12345, yielded
    assert_equal :a, yielder_return
  end
end
