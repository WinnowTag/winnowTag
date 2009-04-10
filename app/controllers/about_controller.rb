# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AboutController < ApplicationController
  skip_before_filter :login_required
  
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

  def info
    @info = Setting.find_or_initialize_by_name("Info")
    @messages = Message.for(current_user).latest(30).since(Message.info_cutoff)
  end
end
