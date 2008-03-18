# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class AboutController < ApplicationController
  def index
    # @about = `svn info #{__FILE__}`
    @about = "TODO: Implement from git"
    
    # if @about =~ /Revision: ([\d]+)/
    #   @revision = $1
    # end
    @revision = "TODO: Implement from git"
    
    # if @about =~ /http:\/\/svn.winnow.peerworks.org\/(.+)\/app\/controllers\/about_controller.rb/
    #   @repos = $1
    # end
    @repos = "TODO: Implement from git"
    
    begin
      @classifier_info = Remote::Classifier.get_info
    rescue
      @classifier_info = nil
    end
  end
  
  def using
    @using = Setting.find_or_initialize_by_name("Using Winnow")
  end
end
