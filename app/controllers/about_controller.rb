# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AboutController < ApplicationController
  def index
    # Capistrano now stores the revision in RAILS_ROOT/REVISION
    #
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
  
  def using
    @using = Setting.find_or_initialize_by_name("Using Winnow")
    @messages = Message.find_for_user_and_global(current_user.id)
  end
end
