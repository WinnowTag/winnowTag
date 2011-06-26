# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# The +TagsController+ is used to manage the viewing of tags.
class TagsController < ApplicationController
  permit "admin", :only => :upload

  # Setup the HMAC authentication with credentials for the classifier role but don't assign to any actions
  with_auth_hmac(HMAC_CREDENTIALS['classifier'], :only => [])
  
  # First thing we need to do is skip standard authentication for actions that the classifier uses
  skip_before_filter :login_required, :only => [:show, :index, :training, :classifier_taggings]
  
  # Require HMAC login for the action the classifier uses for updating a tag, this ensures only the classifier can do this
  before_filter :hmac_login_required, :only => [:classifier_taggings]

  # Now we need to find the tag referenced by the URL.
  #
  # This must be done before the login_or_hmac_required_unless_tag_is_public 
  # filter since we need the tag to check that is a public tag.
  before_filter :find_tag, :only => [:show, :training, :classifier_taggings, :update, :destroy, :merge, :publicize]
  
  # Require normal or HMAC authentication for remaining actions unless the tag is public, in which case allow all access
  before_filter :login_or_hmac_required_unless_tag_is_public, :only => [:show, :index, :training]

  # For operations done by users, make sure it is the owner of the tag doing it
  before_filter :ensure_user_is_tag_owner, :only => [:update, :destroy, :merge, :publicize]

  before_filter :notify_of_tag_subscription_changes, :only => [:index]
  
  # The +index+ action is used to view a logged in users tags.
  # See FeedItemsController#index for an explanation of the html/json requests.  
  #
  # The atom view of the tag index renders a list of all
  # the tags in the system as an atom document. This is
  # used by the classifier so it knows what tags need
  # to be automatically classified as it gets new items.
  def index
    respond_to do |format|
      format.html
      format.json do
        @tags = Tag.search(:user => current_user, :text_filter => params[:text_filter], :own => true,
                           :order => params[:order], :direction => params[:direction])
        @full = true
      end
      format.atom do
        if stale?(:etag => Tag.all_ids) 
          atom = Tag.to_atom(:base_uri => "http://#{request.host}:#{request.port}")
          render :xml => atom.to_xml
        end
      end
    end
  end
  
  # The +public+ action is used to view public tags.
  # See FeedItemsController#index for an explanation of the html/json requests.
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
  
  # The +upload+ action is only accessible to admin users. This action
  # is used to support uploading a tag definition from it's atom document.
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

  # Renders an atom feed for a given tag.
  def show
    respond_to do |wants|
      wants.atom do
        TagUsage.create!(:tag_id => @tag.id, :ip_address => request.remote_ip)
        if stale?(:last_modified => [@tag.updated_on,  @tag.last_classified_at].compact.max)
          atom = @tag.to_atom(:base_uri => "http://#{request.host}:#{request.port}", :since => request.if_modified_since)
          render :xml => atom.to_xml
        end
      end
    end
  end

  # The +create+ action is used to create new tags or copy an existing tag.
  # If copying a tag, and the destination tag already exists, the user will
  # prompted to confirm they want to overwrite the destination tag.
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
          # TODO: Do not redisplay page.
          flash[:error] = t("winnow.notifications.tag_already_exists", :tag => h(to.name))
          render :update do |page|
            page.redirect_to tags_path
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
      begin
        @tag = Tag.create! :name => params[:name], :user => current_user
        respond_to :js
      rescue
        @existing_tag = Tag.find_by_user_id_and_name(current_user.id, params[:name])
      end
    else
      render :nothing => true
    end
  end

  # The +update+ action is used to change a tag's name, description, or bias.
  # If renaming a tag and the destination exists, the user is prompted to
  # merge the two tags together.
  def update
    if @name = params[:tag][:name]
      if current_user.tags.find(:first, :conditions => ['name = ? and id <> ?', @name, @tag.id])
        render :action => "merge.js.rjs"
      else
        if @tag.update_attributes(:name => @name)
          respond_to do |format|
            format.json { render :action => "rename" }
          end
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
  
  # The +merge+ action is triggered during a rename conflict and will handle
  # merging two tags togehter.
  def merge    
    respond_to do |format|
      if merge_to = current_user.tags.find_by_name(params[:tag][:name])
        @tag.merge(merge_to)
        flash[:notice] = t("winnow.notifications.tag_merged", :from => h(@tag.name), :to => h(merge_to.name))
      end
      format.html { redirect_to tags_path }
      # IE Sends the URI fragment with the referer header, which is wrong.
      # We need to strip it before redirecting otherwise redirecting does nothing.
      format.js   { render(:update) { |page| page.redirect_to request.env["HTTP_REFERER"].sub(/#.*$/, "") } }
    end
  end

  # The +destroy+ action will destroy a tag unless it is a tag in the archive
  # account that has subscriptions. If the tag has subscribers, subscriptions and
  # and any blocks are moved to an archive copy.
  def destroy
    if !@tag.tag_subscriptions.empty? && @tag.user.login == "archive"
        render :nothing => true
    else
      @tag.copy_to_archive unless @tag.tag_subscriptions.empty?
      @tag.destroy
      TagSubscription.delete_all(:tag_id => @tag)
      TagExclusion.delete_all(:tag_id => @tag)
      respond_to :js
    end
  end
  
  # Renders an atom feed for the manually tagged items for this tag.
  #
  # This is used by the classifier as training and by the +upload+
  # action as input.
  #
  def training
    base_uri = "http://#{request.host}:#{request.port}"
    
    respond_to do |wants|
      wants.atom do
        if stale?(:last_modified => @tag.updated_on)
          atom = @tag.to_atom(:training_only => true, :base_uri => base_uri)
          render :text => atom.to_xml
        end
      end
    end
  end
  
  # Updates the automatically tagged items for this tag.
  #
  #  - If the request is a POST we update the set of autotagged items.
  #  - If the request is a PUT we replace the set autotagged items.
  #
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
  
  # The +publicize+ action is used to set a tag a public or private.
  def publicize
    @tag.update_attribute(:public, params[:public])
    respond_to :js
  end
  
  # The +globally_exclude+ action blocks a tag for a user.
  def globally_exclude
    @tag = Tag.find(params[:id])
    current_user.tag_exclusions.create! :tag_id => @tag.id unless current_user.globally_excluded?(@tag)
    # Ensure subscription to any tag that is excluded. That way exclusions of
    # a deleted tag can be mostly be handled by way of the subscription to the deleted
    # tag (by tag archive).
    TagSubscription.create! :tag_id => @tag.id, :user_id => current_user.id unless current_user.subscribed?(@tag) || current_user == @tag.user
    respond_to :js
  end
  
  # The +unglobally_exclude+ action unblocks a tag for a user.
  def unglobally_exclude
    @tag = Tag.find(params[:id])
    TagExclusion.delete_all :tag_id => @tag.id, :user_id => current_user.id
    respond_to :js
  end

  # The +subscribe+ action is used to add a tag to a users list of
  # tag subscriptions.
  def subscribe
    if @tag = Tag.find_by_id_and_public(params[:id], true)
      TagSubscription.create! :tag_id => @tag.id, :user_id => current_user.id unless current_user.subscribed?(@tag)
    end
    
    respond_to do |format|
      format.html { redirect_to params[:redirect_to] }
      format.js
    end
  end
  
  # The +unsubscribe+ action is used to remove a tag from a users list of 
  # tag subscriptions.
  def unsubscribe
    if @tag = Tag.find_by_id(params[:id])
      TagSubscription.delete_all :tag_id => @tag.id, :user_id => current_user.id
      TagExclusion.delete_all  :tag_id => @tag.id, :user_id => current_user.id
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
  
  # The +information+ action is used to to make information about a tag
  # available to the client.
  def information
    @tag = Tag.find(params[:id])
  
    respond_to do |format|
      format.json { render :json => {
        :item_count => @tag.feed_items_count,
        :positive_count => @tag.positive_count,
        :negative_count => @tag.negative_count,
        :tooltip => @template.tag_tooltip(@tag),
        :tag_subscriptions_count => @tag.tag_subscriptions.count
      } }
    end
  end

  # The +comments+ action is used to load the comments for a tag.
  # This is lazy-loaded when the user opens a tag to make the 
  # loading of the list of tags faster.
  def comments
    @tag = Tag.find(params[:id])
    @tag.comments.each { |comment| comment.read_by!(current_user) }
    render :layout => false
  end
  
private
  # The +find_tag+ before_filter will inspect parameters and load the
  # tag based on the id or the user login/tag name combination.
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
  
  # Checks that the user is either logged, hmac_authenticated or the tag is public.
  def login_or_hmac_required_unless_tag_is_public
    (@tag && @tag.public?) || logged_in? || hmac_authenticated? || login_required
  end
  
  # The +ensure_user_is_tag_owner+ before filter is used to ensure only the
  # tag owner can be doing the requested action.
  def ensure_user_is_tag_owner
    access_denied if current_user.nil? || current_user.id != @tag.user_id
  end
end
