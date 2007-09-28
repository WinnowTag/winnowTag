# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class TokenAtomizerWorker < BackgrounDRb::Worker::RailsBase
  extend Forwardable
  attr_reader :atomizer
  def_delegators :@atomizer, :globalize, :localize

  def do_work(args);
    # This relies on proper setting of the TokenAtomizer configuration in environment.rb
    @atomizer = Bayes::TokenAtomizer.new
    logger.info("Token Atomizer initialization complete: #{@atomizer}")
  end
end
TokenAtomizerWorker.register unless RAILS_ENV == 'test'
