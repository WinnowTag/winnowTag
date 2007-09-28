# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class TaggingsController < ApplicationController
  helper :feed_items
  verify :method => :post, :render => SHOULD_BE_POST
  verify :params => :tagging, :render => MISSING_PARAMS
  
  # Creates a single tagging for a <Taggable, Tagger, Tag>
  def create
    respond_to do |wants|
      params[:tagging][:tag] = Tag.find_or_create_by_name(params[:tagging][:tag])
      @tagging = current_user.taggings.build(params[:tagging])
      @taggable = @tagging.taggable
      
      if @tagging.save
        wants.html { flash[:notice] = "Tag applied"; redirect_to :back }        
        wants.js   { render :template => "#{@tagging.taggable_type.underscore.pluralize}/tags_updated.rjs" }
      else
        wants.html { flash[:error] = "Tagging failed"; redirect_to :back }
        wants.js   { render :update do |page| page.alert("Tagging failed") end }
      end
    end 
  end
  
  # Destroys taggings
  #
  #  Accepted Parameters:
  #    - tagging: 
  #         taggable_type/taggable_id: The type and id of a taggable to destroy a tagging on.
  #         tag: The name of the tag to destroy the tagging on the taggable.
  #
  def destroy
    respond_to do |wants|
      tagging = params[:tagging]
      @taggable = tagging[:taggable_type].constantize.find(tagging[:taggable_id])
      
      current_user.taggings.find_by_taggable(@taggable, :all, 
                                            :conditions => {:tag_id => Tag.find_or_create_by_name(tagging[:tag]).id}).
                                            each(&:destroy)
    
      wants.html { redirect_to(:back) }
      wants.js   { render :template => "#{@taggable.class.name.underscore.pluralize}/tags_updated.rjs" }
    end
  end
end
