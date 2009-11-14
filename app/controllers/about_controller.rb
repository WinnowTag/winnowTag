# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +AboutController+ is publically accessible and does not require any
# user to be logged in.
class AboutController < ApplicationController
  skip_before_filter :login_required
  skip_before_filter :check_if_user_must_update_password
  around_filter :no_logging, :only => :info

  # The +index+ action displays information about the version of Winnow
  # and the version of the Classifier it is communicating with.
  def index
    # Capistrano now stores the revision in RAILS_ROOT/REVISION
    cap_rev_file = File.join(RAILS_ROOT, 'REVISION')

    if File.exists?(cap_rev_file)
      @revision = File.read(cap_rev_file)
    else
      @revision = `git rev-parse --short HEAD`.chomp
    end

    begin
      @classifier_info = Remote::Classifier.get_info
    rescue
      @classifier_info = nil
    end
  end

  # The +info+ action is the default landing page for Winnow and its content
  # can be edited in the admin/info section.
  def info
    @info = Setting.find_or_initialize_by_name("Info")
    @messages = Message.for(current_user).latest(30).pinned_or_since(Message.info_cutoff)
  end
  
private
  
  def no_logging
    logger.silence do
      yield
    end
  end
end
