# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# The tags controller provides an interface to a users tags.
#
# The CRUD operations here don't actually work on the tag models
# instead they apply bulk operations to a users use of the tag,
# the Tag models themselves never change.
#
# You can think of it as the +TaggingsController+ operates on 
# single uses of the tag by the user and the +TagsController+
# operates on the many +Taggings+ that use a given +Tag+.
#
class TagsController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :find_tag, :except => [:index, :create, :auto_complete_for_tag_name, :public]
  
  # Show a table of the users tags
  def index
    respond_to do |wants|
      @title = 'My Tags'
      @tags = current_user.tags_with_count
      @classifier = current_user.classifier
      wants.html
      wants.xml {render :xml => @tags.to_xml}
    end
  end

  # Create is actually a copy of an existing tag.
  #
  # :copy must be the name of a tag to copy
  def create
    begin
      if params[:copy]
        source = current_user
        from = current_user.tags.find_by_name(params[:copy])
        to = Tag(current_user, "Copy of #{params[:copy]}")        
        from.copy(to)
        
        flash[:notice] = "'#{from.name}' successfully copied to '#{to.name}'"        
      else
        flash[:error] = "Provide a tag to copy"
      end
    rescue
      logger.warn($!)
      flash[:error] = $!.message
    end
    
    redirect_to tags_path
  end
  
  def edit
    respond_to do |wants|
      wants.html
      wants.js { headers['Content-Type'] = 'text/html'; render :partial => 'form' }
    end
  end

  # Merge or rename a tag.
  #
  # This doesn't actually modify the tag, instead all of the 
  # current_user's instances of old_tag will be changed to instances of new_tag.
  #
  def update
    if (merge_to = current_user.tags.find_by_name(params[:tag][:name])) && (merge_to != @tag)
      initial_size = @tag.manual_taggings.size
      number_merged = @tag.merge(merge_to)
      
      if number_merged == initial_size
        flash[:notice] = "#{pluralize(number_merged, 'tag')} merged from '#{@tag}' to '#{merge_to}'"
      else
        flash[:warning] = "#{pluralize(number_merged, 'tag')} merged from '#{@tag}' to '#{merge_to}' " +
                            "with #{pluralize(initial_size - number_merged, 'conflict')}"
      end
    else
      @tag.name = params[:tag][:name]
      
      if @tag.save       
        flash[:notice] = "Tag renamed"        
      else
        flash[:error] = @tag.errors.full_messages.join('<br/>')
      end
    end
    
    redirect_to :back
  end

  # Destroy the users use of the tag
  #
  # User tags are loaded and their destroy method is called. Classifier tags
  # are just deleted using SQL.  This because we can completely remove the 
  # classifier tags, but user tags need to be marked as deleted and then used
  # in untraining during the next classification run.
  # 
  def destroy
    @tag.destroy
    flash[:notice] = "Deleted #{@tag.name}."
    redirect_to :back
  end
  
  # Action to get tag names for the auto-complete tag field on the merge/rename form.
  #
  def auto_complete_for_tag_name
    @tag = current_user.tags.find_by_name(params[:id])
    
    @q = params[:tag][:name]
    @tags = current_user.tags.find(:all, 
          :conditions => ['lower(name) LIKE lower(?)', "%#{@q}%"])
    @tags -= Array(@tag)
    render :inline => '<%= auto_complete_result(@tags, :name, @q) %>'
  end
  
  def public
  end
  
  private
  def find_tag
    @tag = current_user.tags.find_by_name(params[:id])
    
    if @tag.nil?
      render(:status => 404, :text => "#{params[:id]} not found.") and return false
    else
      true
    end
  end
end
