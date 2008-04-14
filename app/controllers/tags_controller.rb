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
  skip_before_filter :login_required, :only => [:show, :index, :training, :classifier_taggings]
  before_filter :login_required_unless_local, :only => :index
  before_filter :find_tag, :except => [:index, :create, :auto_complete_for_tag_name, :public, :subscribe, :unsubscribe, :globally_exclude, :auto_complete_for_sidebar]
  before_filter :ensure_user_is_tag_owner, :only => [:update, :destroy]
  before_filter :ensure_user_is_tag_owner_unless_local, :only => :classifier_taggings
  
  def index
    respond_to do |wants|
      wants.html do
        @search_term = params[:search_term]
        
        setup_sortable_columns
        @tags  = current_user.tags.find_all_with_count(:excluder => current_user, :search_term => @search_term, :order => sortable_order('tags', :field => 'name', :sort_direction => :asc))
        @tags += Tag.find_all_with_count(:excluder => current_user, :search_term => @search_term, :subscribed_by => current_user, :order => sortable_order('tags', :field => 'name', :sort_direction => :asc))
        @tags = @tags.sort_by(&:name)
      end
      wants.atomsvc do        
        conditional_render(Tag.maximum(:created_on)) do
          atomsvc = Tag.to_atomsvc(:base_uri => "http://#{request.host}:#{request.port}")
          render :xml => atomsvc.to_xml
        end
      end
    end
  end
  
  def public
    @search_term = params[:search_term]
    setup_sortable_columns
    @tags = Tag.find_all_with_count(:search_term => @search_term, :conditions => ["tags.public = ?", true], :subscriber => current_user,
                                    :order => sortable_order('tags', :field => 'name', :sort_direction => :asc))
  end

  def show
    respond_to do |wants|
      wants.atom do        
        conditional_render([@tag.updated_on,  @tag.last_classified_at].compact.max) do |since|
          atom = @tag.to_atom(:base_uri => "http://#{request.host}:#{request.port}", :since => since)
          render :xml => atom.to_xml
        end
      end
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
    elsif params[:name]
      @tag = Tag.create! :name => params[:name], :user => current_user
      respond_to :js
    else
      render :nothing => true
    end
  end

  # Rename, or change the comment on a tag.
  #
  def update
    if @name = params[:tag][:name]
      if current_user.tags.find(:first, :conditions => ['name = ? and id <> ?', @name, @tag.id])
        render :action => "merge.js.rjs"
      else
        if @tag.update_attributes(:name => @name)
          flash[:notice] = "Tag Renamed"
        else
          flash[:error] = @tag.errors.full_messages.join('<br/>')
        end
        respond_to do |format|
          format.html { redirect_to tags_path }
          format.js   { render(:update) { |p| p.redirect_to request.env["HTTP_REFERER"] } }
        end        
      end
    elsif comment = params[:tag][:comment]
      @tag.update_attribute(:comment, comment)
      render :text => @tag.comment
    elsif bias = params[:tag][:bias]
      @tag.update_attribute(:bias, bias)
      render :nothing => true
    end
  end
  
  def merge    
    respond_to do |format|
      if merge_to = current_user.tags.find_by_name(params[:tag][:name])
        @tag.merge(merge_to)
        flash[:notice] = "'#{@tag}' merged with '#{merge_to}'"
      end
      
      format.html { redirect_to tags_path }
      format.js   { render(:update) { |p| p.redirect_to request.env["HTTP_REFERER"] } }
    end
  end

  def destroy
    @tag.destroy
    TagSubscription.delete_all(:tag_id => @tag)
    respond_to :js
  end
  
  def training
    base_uri = "http://#{request.host}:#{request.port}"
    
    respond_to do |wants|
      wants.atom do
        conditional_render(@tag.updated_on) do
          atom = @tag.to_atom(:training_only => true, :base_uri => base_uri)
          render :text => atom.to_xml
        end
      end
    end
  end
  
  def classifier_taggings    
    if !(request.post? || request.put?)
      render :status => "405", :nothing => true
    elsif params[:atom].nil?
      render :status => "400", :nothing => true    
    elsif request.post? || request.put?
      request.post? ? @tag.create_taggings_from_atom(params[:atom]) : 
                      @tag.replace_taggings_from_atom(params[:atom])
      render :status => "204", :nothing => true
    end
  end
  
  # Action to get tag names for the auto-complete tag field on the merge/rename form.
  def auto_complete_for_tag_name
    @tag = current_user.tags.find_by_name(params[:id])
    
    @q = params[:tag][:name]
    @tags = current_user.tags.find(:all, 
          :conditions => ['LOWER(name) LIKE LOWER(?)', "%#{@q}%"])
    @tags -= Array(@tag)
    render :inline => '<%= auto_complete_result(@tags, :name, @q) %>'
  end
  
  def auto_complete_for_sidebar
    @q = params[:tag][:name]
    
    conditions = ["LOWER(name) LIKE LOWER(?) AND ((public = ? AND user_id != ?) OR (user_id = ? AND show_in_sidebar = ?))"]
    values = ["%#{@q}%", true, current_user.id, current_user.id, false]
    
    tag_ids = current_user.subscribed_tags.map(&:id)
    if !tag_ids.blank?
      conditions << "id NOT IN (?)"
      values << tag_ids
    end
    
    @tags = Tag.find(:all, :conditions => [conditions.join(" AND "), *values], :limit => 30)
    render :layout => false
  end
  
  def publicize
    @tag.update_attribute(:public, params[:public])
    unless @tag.public?
      TagSubscription.delete_all(:tag_id => @tag)
    end
    render :nothing => true
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
    if @tag = Tag.find_by_id_and_public(params[:id], true)
      TagSubscription.delete_all :tag_id => @tag.id, :user_id => current_user.id
      TagExclusion.delete_all :tag_id => @tag.id, :user_id => current_user.id
      Folder.remove_tag(current_user, @tag.id)
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
  
  def sidebar
    if @tag = current_user.tags.find(params[:id])
      @tag.update_attribute :show_in_sidebar, params[:sidebar]      

      unless @tag.show_in_sidebar?
        Folder.remove_tag(current_user, @tag.id)
        respond_to :js
        return
      end
    end
    render :nothing => true
  end
  
private
  def find_tag
    if params[:user] && params[:tag_name]
      @user = User.find_by_login(params[:user])
      unless @user && @tag = @user.tags.find_by_name(params[:tag_name])
        render :status => 404, :text => "#{params[:user]} and no tag '#{params[:tag_name]}'."      
      end
    elsif params[:id]
      begin
        @tag = current_user.tags.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render :status => 404, :text => "Tag with id #{params[:id]} not found."
      end
    end
    
    if @tag && !@tag.public? && !local_request? && (current_user.nil? || @tag.user_id != current_user.id)
      access_denied
    end
  end
  
  def ensure_user_is_tag_owner
    access_denied if current_user.nil? || current_user.id != @tag.user_id
  end
  
  def ensure_user_is_tag_owner_unless_local
    ensure_user_is_tag_owner unless local_request?
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
  
  def conditional_render(last_modified)   
    since = Time.rfc2822(request.env['HTTP_IF_MODIFIED_SINCE']) rescue nil

    if since && last_modified && since >= last_modified
      head :not_modified
    else
      response.headers['Last-Modified'] = last_modified.httpdate if last_modified
      yield(since)
    end
  end
end
