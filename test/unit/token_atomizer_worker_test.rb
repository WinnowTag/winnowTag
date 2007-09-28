# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
$: << RAILS_ROOT + '/vendor/plugins/backgroundrb/server/lib'
require 'backgroundrb/middleman'
require 'backgroundrb/worker_rails'
require 'workers/token_atomizer_worker'

# Stub out worker initialization
class BackgrounDRb::Worker::Base
  def initialize(args = nil, jobkey = nil); end
  def logger; ActiveRecord::Base.logger; end
end

class TokenAtomizerWorkerTest < Test::Unit::TestCase
  fixtures :tokens
  
  def test_worker_delegation
    Bayes::TokenAtomizer.expects(:new).returns(mock(:localize => true, :globalize => true))
    worker = TokenAtomizerWorker.new
    worker.do_work(nil)
    worker.localize
    worker.globalize
  end
  
  def test_worker_creates_db_worker
    ta = TokenAtomizerWorker.new
    ta.do_work(nil)    
    assert_equal(ActiveRecord::Base.connection.connection, ta.atomizer.store.connection)
  end
end
