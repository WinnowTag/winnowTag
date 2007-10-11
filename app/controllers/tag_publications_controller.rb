# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# The TagPublication Controller scoping
# using REST style path prefixes that allow
# a caller to scope the tag_publications to a user
#
class TagPublicationsController < ApplicationController
  skip_before_filter :login_required, :only => :show
  skip_before_filter :load_view, :only => :show
  before_filter :find_base
  before_filter :convert_tag
  
  def index
    @tag_publications = @user.tag_publications
    
    respond_to do |wants|
      wants.html { render :action => 'index'}
      wants.xml  { render :xml => @tag_publications.to_xml }
    end
  end
  
  def show    
    if @tag_publication = @user.tag_publications.find_by_tag_id(Tag.find_or_create_by_name(params[:id]).id)
      respond_to do |format|
        format.atom do
          last_modified = @tag_publication.classifier.last_executed
          since = Time.rfc2822(request.env['HTTP_IF_MODIFIED_SINCE']) rescue nil

          if since && last_modified && since >= last_modified
            head :not_modified
          else
            @feed_items = @tag_publication.find_feed_items(:limit => 100, :order => 'time desc')    
            response.headers['Last-Modified'] = last_modified.httpdate if last_modified         
            render :action => 'show.rxml', :layout => false
          end
        end
      end
    else
      render :text => "#{params[:id]} has not been published by #{@user.login}", :status => 404
    end
  end
  
  def new
    @tag_publication = @user.tag_publications.build(params[:tag_publication])
    
    respond_to do |wants|
      wants.html
      wants.js   { headers['Content-Type'] = 'text/html'; render :partial => 'form' }
    end
  end
  
  def create
    @tag_publication = @user.tag_publications.build(params[:tag_publication])
    
    respond_to do |wants|
      if @tag_publication.save
        @tag_publication.classifier.start_background_classification rescue logger.warn($!)
        flash[:notice] = "#{@tag_publication.tag} successfully published"
      else
        flash[:error] = "Could not publish tag: #{@tag_publication.errors.full_messages.join(', ')}."
      end
      wants.html {redirect_to :back}
    end
  end
  
  def destroy
    publication = @user.tag_publications.find(params[:id])
    
    if publication and current_user == @user
      publication.destroy 
      flash[:notice] = "Published Tag Deleted"
    else
      flash[:warning] = "You aren't allow to delete another users tag"
    end
    
    redirect_to :back
  end
  
  private
  def find_base
    @user = User.find_by_login(params[:user_id])
  end
  
  def convert_tag
    if params[:tag_publication] and params[:tag_publication][:tag].is_a?(String)
      params[:tag_publication][:tag] = Tag.find_or_create_by_name(params[:tag_publication][:tag])
    end
  end
end