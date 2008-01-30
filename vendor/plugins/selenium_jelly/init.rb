if RAILS_ENV == 'test'
  require File.dirname(__FILE__) + '/lib/selenium'
  require File.dirname(__FILE__) + '/lib/selenium/base'
  require File.join(RAILS_ROOT, 'config', 'selenium', 'osx')
end
