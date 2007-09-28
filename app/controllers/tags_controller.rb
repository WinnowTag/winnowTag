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
  before_filter :find_tag, :except => [:index, :create, :auto_complete_for_tag_name]
  
  # Show a table of the users tags
  def index
    respond_to do |wants|
      @title = 'My Tags'
      @tags = current_user.tags_with_count
      @classifier = current_user.classifier
      @classifier_counts = @classifier.tags_with_count.hash_by(:name)
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
        if params[:copy] =~ /pub_tag:(\d+)/
          source = TagPublication.find($1)
          from = source.tag
          to = Tag("Copy of #{source.name}")
        else
          source = current_user
          from = current_user.tags.find_by_name(params[:copy])
          to = Tag("Copy of #{params[:copy]}")
        end
        
        source.copy_tag(from, to, current_user)
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
    new_tag = Tag.find_or_create_by_name(params[:tag][:name])
    rename_tagging = RenameTagging.create(:old_tag => @tag, :new_tag => new_tag, :tagger => current_user)
    if rename_tagging.valid?       
      flash[:notice] = rename_tagging.message        
    else
      flash[:error] = rename_tagging.errors.full_messages.join('<br/>')
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
    taggings = current_user.taggings.find_by_tag(@tag).each(&:destroy)
    current_user.classifier.taggings.delete_all!("tag_id = #{@tag.id}")
    flash[:notice] = "Deleted #{pluralize(taggings.size, 'use')} of #{@tag.name}."
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
