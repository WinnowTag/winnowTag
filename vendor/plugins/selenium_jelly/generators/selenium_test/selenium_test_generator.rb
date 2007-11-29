class SeleniumTestGenerator < Rails::Generator::Base
  def initialize(runtime_args, runtime_options = {})
    super
    usage if @args.empty?
  end

  def banner
    "Usage: #{$0} #{spec.name} test_name"
  end

  def manifest
    record do |m|
      m.directory 'test/selenium'
      m.template 'selenium_test.rb', File.join('test/selenium', file_name)
    end
  end
  
  def file_name
    "#{File.basename(args[0]).underscore}_selenium_test.rb"
  end
  
  def class_name
    File.basename(args[0]).camelize
  end
  
  def table_name
    File.basename(args[0]).underscore.pluralize
  end
end
