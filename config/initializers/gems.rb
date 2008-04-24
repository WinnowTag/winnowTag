require 'tzinfo'
require 'digest/sha1'

gem 'mysql'

gem 'hpricot'
require 'hpricot'

gem 'bcrypt-ruby'
require 'bcrypt'

gem 'fastercsv'
require 'fastercsv'

# 3.0.4 is buggy -- Required in environment.rb so that action pack does not require 3.0.4
# gem 'RedCloth', '3.0.3'

gem 'ratom', '0.3.4'
require 'atom'
