# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# The TagsController provides an interface to a user's tags.
class TagsController < ApplicationController
  permit "admin", :only => :upload

  # Setup the HMAC authentication with credentials for the classifier role but don't assign to any actions
  with_auth_hmac(HMAC_CREDENTIALS['classifier'], :only => [])
  
  # First thing we need to do is skip standard authentication for actions that the classifier uses
  skip_before_filter :login_required, :only => [:show, :index, :training, :classifier_taggings]
  
  # Require HMAC login for the action the classifier uses for updating a tag, this ensures only the classifier can do this
  before_filter :hmac_login_required, :only => [:classifier_taggings]

  # Now we need to find the tag reference by the URL.
  #
  # This must be done before the login_or_hmac_required_unless_tag_is_public 
  # filter since we need the tag to check that is a public tag.
  #
  before_filter :find_tag, :only => [:show, :training, :classifier_taggings, :update, :destroy, :merge, :publicize]
  
  # Require normal or HMAC authentication for remaining actions unless the tag is public, in which case allow all access
  before_filter :login_or_hmac_required_unless_tag_is_public, :only => [:show, :index, :training]

  # For operations done by users, make sure it is the own of the tag doing it
  before_filter :ensure_user_is_tag_owner, :only => [:update, :destroy, :merge, :publicize]
  
  def index
    respond_to do |format|
      format.html
      format.json do
        @tags = Tag.search(:user => current_user, :text_filter => params[:text_filter], :own => true,
                           :order => params[:order], :direction => params[:direction])
        @full = true
      end
      format.atom do        
        conditional_render(Tag.maximum(:created_on)) do
          atom = Tag.to_atom(:base_uri => "http://#{request.host}:#{request.port}")
          render :xml => atom.to_xml
        end
      end
    end
  end
  
  def public
    respond_to do |format|
      format.html
      format.json do
        @tags = Tag.public.search(:user => current_user, :text_filter => params[:text_filter], 
                           :order => params[:order], :direction => params[:direction], 
                           :limit => limit, :offset => params[:offset])
        @full = @tags.size < limit
      end
    end
  end
  
  # Support uploading a tag definition from it's atom document
  #
  def upload
    respond_to do |format|
      format.html do
        atom = Atom::Feed.load_feed(params[:atom].read)
        logger.info("Atom title: " + atom.title)

        tag = current_user.tags.create_from_atom(atom)
        if tag.errors.empty?
          flash[:notice] = "Tag #{tag.name} imported"
          redirect_to tags_path          
        else
          flash.now[:error] = tag.errors.full_messages.join("\n")
          render :action => 'index'
        end
      end
    end
  end

  def show
    respond_to do |wants|
      wants.atom do
        TagUsage.create!(:tag_id => @tag.id, :ip_address => request.remote_ip)
        conditional_render([@tag.updated_on,  @tag.last_classified_at].compact.max) do |since|
          atom = @tag.to_atom(:base_uri => "http://#{request.host}:#{request.port}", :since => since)
          render :xml => atom.to_xml
        end
      end
    end
  end

  # Create is actually a copy of an existing tag.
  #
  # <tt>:copy</tt> must be the name of a tag to copy
  def create
    if params[:copy] && params[:name]
      from = Tag.find_by_id(params[:copy])
      to = Tag.find_by_user_id_and_name(current_user.id, params[:name])
      if to
        if params[:overwrite] =~ /true/i
          from.overwrite(to)
          flash[:notice] = t("winnow.notifications.tag_copied", :from => h(from.name), :to => h(to.name))
          render :update do |page|
            page.redirect_to tags_path
          end
        else
          render :update do |page|
            # TODO: broken?
            page << <<-EOJS
              if(confirm(#{t('winnow.tags.main.replace', :to => h(params[:name]), :from => h(from.name)).to_json}) {
                #{remote_function(:url => hash_for_tags_path(:copy => from, :name => params[:name], :overwrite => true))};
              }
            EOJS
          end
        end
      else
        to = Tag(current_user, params[:name])
        from.copy(to)
      
        flash[:notice] = t("winnow.notifications.tag_copied", :from => h(from.name), :to => h(to.name))
      
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

  # Rename, or change the description on a tag.
  def update
    if @name = params[:tag][:name]
      if current_user.tags.find(:first, :conditions => ['name = ? and id <> ?', @name, @tag.id])
        render :action => "merge.js.rjs"
      else
        if @tag.update_attributes(:name => @name)
          render :action => "rename.js.rjs"
        else
          @tag.reload
          render :action => "error.js.rjs"
        end
      end
    elsif description = params[:tag][:description]
      @tag.update_attribute(:description, description)
      render :partial => "update_description"
    elsif bias = params[:tag][:bias]
      @tag.update_attribute(:bias, bias)
      render :nothing => true
    end
  end
  
  def merge    
    respond_to do |format|
      if merge_to = current_user.tags.find_by_name(params[:tag][:name])
        @tag.merge(merge_to)
        flash[:notice] = t("winnow.notifications.tag_merged", :from => h(@tag.name), :to => h(merge_to.name))
      end
      
      format.html { redirect_to tags_path }
      format.js   { render(:update) { |page| page.redirect_to request.env["HTTP_REFERER"] } }
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
    if params[:atom].nil?
      render :status => :bad_request, :text => "Missing Atom Document"
    elsif request.post?
      @tag.create_taggings_from_atom(params[:atom])
      render :status => :no_content, :nothing => true
    elsif request.put?
      @tag.replace_taggings_from_atom(params[:atom])
      render :status => :no_content, :nothing => true
    end
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
    
    @tags = Tag.find(:all, :conditions => [conditions.join(" AND "), *values], :order => "tags.sort_name", :limit => 30)
    render :layout => false
  end
  
  def publicize
    @tag.update_attribute(:public, params[:public])
    unless @tag.public?
      TagSubscription.delete_all(:tag_id => @tag)
    end
    respond_to :js
  end
  
  def globally_exclude
    @tag = Tag.find(params[:id])
    if params[:globally_exclude] =~ /true/i
      current_user.tag_exclusions.create! :tag_id => @tag.id
      # TagSubscription.delete_all :tag_id => @tag.id, :user_id => current_user.id
      Folder.remove_tag(current_user, @tag.id)
    else
      TagExclusion.delete_all :tag_id => @tag.id, :user_id => current_user.id
    end
    respond_to :js
  end
  
  def subscribe
    if @tag = Tag.find_by_id_and_public(params[:id], true)
      if params[:subscribe] =~ /true/i
        if !current_user.subscribed?(@tag)
          TagSubscription.create! :tag_id => @tag.id, :user_id => current_user.id
          # TagExclusion.delete_all :tag_id => @tag.id, :user_id => current_user.id
        end
      else
        TagSubscription.delete_all :tag_id => @tag.id, :user_id => current_user.id
        Folder.remove_tag(current_user, @tag.id)
      end
    end

    respond_to do |format|
      format.html { redirect_to params[:redirect_to] }
      format.js
    end
  end
  
  def unsubscribe
    if @tag = Tag.find_by_id_and_public(params[:id], true)
      TagSubscription.delete_all :tag_id => @tag.id, :user_id => current_user.id
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
    end


    if @tag.show_in_sidebar?
      respond_to do |format|
        format.html { redirect_to params[:redirect_to] }
        format.js { head :ok }
      end
    else
      Folder.remove_tag(current_user, @tag.id)
      respond_to :js
    end
  end
  
  def information
    @tag = Tag.find(params[:id])
    render :layout => false
  end

  def comments
    @tag = Tag.find(params[:id])
    @tag.comments.each { |comment| comment.read_by!(current_user) }
    render :layout => false
  end
  
private
  def find_tag
    if params[:user] && params[:tag_name]
      @user = User.find_by_login(params[:user])
      unless @user && @tag = @user.tags.find_by_name(params[:tag_name])
        render :status => :not_found, :text => t("winnow.tags.main.not_found", :login => h(@user.login), :tag_name => h(params[:tag_name]))
      end
    elsif params[:id]
      begin
        @tag = Tag.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render :status => :not_found, :text => t("winnow.tags.main.id_not_found", :tag_id => h(params[:id]))
      end
    else
      render :status => :not_found, :text => t("winnow.tags.main.id_not_found", :tag_id => h(params[:id]))
    end
  end
  
  def login_or_hmac_required_unless_tag_is_public
    (@tag && @tag.public?) || logged_in? || hmac_authenticated? || login_required
  end
  
  def ensure_user_is_tag_owner
    access_denied if current_user.nil? || current_user.id != @tag.user_id
  end
end
