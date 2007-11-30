require 'active_record/fixtures'

class Test::Unit::TestCase
  class << self
    remove_method :method_added
  end
end

require 'test/unit/testcase'

class Test::Unit::TestCase
  cattr_accessor :_allow_setup_or_teardown_definition
  self._allow_setup_or_teardown_definition = false
  
  class_inheritable_array :_setup_blocks, :_teardown_blocks
  self._setup_blocks = self._teardown_blocks = []
  
  class << self
    # Define a block to be executed before each test method. Can be called multiple times.
    # 
    # class PersonTest < Test::Unit::TestCase
    #   setup do
    #      User.current = User.find(:first)
    #   end
    # end
    def setup(&block)
      self._setup_blocks = [block]
    end
    
    # See <tt>setup</tt>
    def teardown(&block)
      self._teardown_blocks = [block]
    end
  end
  
  def setup_with_blocks #:nodoc:
    setup_with_fixtures
    _setup_blocks.each { |p| p.bind(self).call } unless _setup_blocks.nil?
  end
  alias_method :setup, :setup_with_blocks
    
  def teardown_with_blocks #:nodoc:
    teardown_with_fixtures
    _teardown_blocks.each { |p| p.bind(self).call } unless _teardown_blocks.nil?
  end
  alias_method :teardown, :teardown_with_blocks
  
  # Backwards compatibility for definitions of setup and teardown methods
  def self.method_added(method) #:nodoc:
    method = method.to_s
    method_definition = instance_method(method)
    
    case method
      when 'setup'
        unless self._allow_setup_or_teardown_definition
          self._setup_blocks = [method_definition]
          allow_setup_or_teardown_definition { alias_method :setup, :setup_with_blocks }
        end
	
      when 'teardown'
        unless self._allow_setup_or_teardown_definition
          self._teardown_blocks = [method_definition]
          allow_setup_or_teardown_definition { alias_method :teardown, :teardown_with_blocks }
        end
    end
  end
  
  def self.allow_setup_or_teardown_definition
    self._allow_setup_or_teardown_definition = true
    yield
    self._allow_setup_or_teardown_definition = false
  end
end
