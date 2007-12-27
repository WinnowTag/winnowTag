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
  skip_before_filter :login_required, :only => :show
  before_filter :find_tag, :except => [:index, :show, :create, :auto_complete_for_tag_name, :public, :subscribe, :unsubscribe, :globally_exclude]
  
  def index
    respond_to do |wants|
      wants.html do
        @search_term = params[:search_term]
        
        setup_sortable_columns
        @tags = current_user.tags.find_all_with_count(:excluder => current_user, :search_term => @search_term, :order => sortable_order('tags', :field => 'name', :sort_direction => :asc))
        @subscribed_tags = Tag.find_all_with_count(:excluder => current_user, :search_term => @search_term, :subscribed_by => current_user, :order => sortable_order('tags', :field => 'name', :sort_direction => :asc))
      end
      wants.xml { render :xml => current_user.tags_with_count.to_xml }
    end
  end
  
  def show
    user = User.find_by_login(params[:user_id])

    if user and @tag = user.tags.find_by_id(params[:id])
      respond_to do |wants|
        wants.atom do        
          last_modified = if @tag.updated_on and @tag.last_classified_at
            [@tag.updated_on, @tag.last_classified_at].max
          else
            (@tag.updated_on or @tag.last_classified_at)
          end
          
          since = Time.rfc2822(request.env['HTTP_IF_MODIFIED_SINCE']) rescue nil

          if since && last_modified && since >= last_modified
            head :not_modified
          else
            response.headers['Last-Modified'] = last_modified.httpdate if last_modified
            render :layout => false
          end
        end
      end
    else
      render :text => "#{params[:id]} has not been published by #{params[:user_id]}", :status => 404
    end
  end

  # Create is actually a copy of an existing tag.
  #
  # :copy must be the name of a tag to copy
  def create
    if params[:copy] && params[:name]
      from = Tag.find_by_id(params[:copy])
      to = Tag.find_by_user_id_and_name(current_user.id, params[:name])
      if to
        if params[:overwrite] =~ /true/i
          from.overwrite(to)
          flash[:notice] = "'#{from.name}' successfully copied to '#{to.name}'"
          render :update do |page|
            page.redirect_to tags_path
          end
        else
          render :update do |page|
            page << <<-EOJS
              if(confirm("Tag '#{params[:name]}' already exists. This copy will completely replace it with a copy of '#{from.name}'")) {
                #{remote_function(:url => hash_for_tags_path(:copy => from, :name => params[:name], :overwrite => true))};
              }
            EOJS
          end
        end
      else
        to = Tag(current_user, params[:name])
        from.copy(to)
      
        flash[:notice] = "'#{from.name}' successfully copied to '#{to.name}'"
      
        render :update do |page|
          page.redirect_to tags_path
        end
      end
    else
      render :nothing => true
    end
  end
  
  def edit
    respond_to do |wants|
      wants.html
      wants.js { headers['Content-Type'] = 'text/html'; render :partial => 'form' }
    end
  end

  # Merge, rename, or change the comment on a tag.
  def update
    if name = params[:tag][:name]
      if (merge_to = current_user.tags.find_by_name(name)) && (merge_to != @tag)
        @tag.merge(merge_to)
        flash[:notice] = "'#{@tag}' merged with '#{merge_to}'"
      else
        if @tag.update_attributes :name => name
          flash[:notice] = "Tag Renamed"
        else
          flash[:error] = @tag.errors.full_messages.join('<br/>')
        end
      end
      respond_to do |format|
        format.html{ redirect_to tags_path }
        format.js { render(:update) { |p| p.redirect_to tags_path } }
      end
    elsif comment = params[:tag][:comment]
      @tag.update_attribute(:comment, comment)
      render :text => @tag.comment
    elsif bias = params[:tag][:bias]
      @tag.update_attribute(:bias, bias)
      render :nothing => true
    end
  end

  def destroy
    @tag.destroy
    TagSubscription.delete_all(:tag_id => @tag)

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
  
  def publicize
    @tag.update_attribute(:public, params[:public])
    unless @tag.public?
      TagSubscription.delete_all(:tag_id => @tag)
    end
  end
  
  def public
    @search_term = params[:search_term]
    setup_sortable_columns
    @tags = Tag.find_all_with_count(:search_term => @search_term, :conditions => ["tags.public = ?", true], :subscriber => current_user,
                                    :order => sortable_order('tags', :field => 'name', :sort_direction => :asc))
  end

  def globally_exclude
    @tag = Tag.find(params[:id])
    if params[:globally_exclude] =~ /true/i
      current_user.tag_exclusions.create! :tag_id => @tag.id
    else
      TagExclusion.delete_all :tag_id => @tag.id, :user_id => current_user.id
    end
    render :nothing => true
  end
  
  def subscribe
    if tag = Tag.find_by_id_and_public(params[:id], true)
      if params[:subscribe] =~ /true/i
        TagSubscription.create! :tag_id => tag.id, :user_id => current_user.id
      else
        TagSubscription.delete_all :tag_id => tag.id, :user_id => current_user.id
        TagExclusion.delete_all :tag_id => tag.id, :user_id => current_user.id
      end
    end
    render :nothing => true
  end
  
  def unsubscribe
    if tag = Tag.find_by_id_and_public(params[:id], true)
      TagSubscription.delete_all :tag_id => tag.id, :user_id => current_user.id
      TagExclusion.delete_all :tag_id => tag.id, :user_id => current_user.id
    end
    redirect_to :back
  end
  
private
  def find_tag
    @tag = current_user.tags.find_by_id(params[:id])    
    render :status => 404, :text => "#{params[:id]} not found." unless @tag
  end
  
  def setup_sortable_columns
    add_to_sortable_columns('tags', :field => 'name')
    add_to_sortable_columns('tags', :field => 'subscribe')
    add_to_sortable_columns('tags', :field => 'public')
    add_to_sortable_columns('tags', :field => 'training_count')
    add_to_sortable_columns('tags', :field => 'classifier_count')
    add_to_sortable_columns('tags', :field => 'last_used_by')
    add_to_sortable_columns('tags', :field => 'login')
    add_to_sortable_columns('tags', :field => 'globally_exclude')
  end
end
