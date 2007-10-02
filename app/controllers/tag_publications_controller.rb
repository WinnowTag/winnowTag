# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

# The TagPublication Controller provides two scoping
# methods using REST style path prefixes that allow
# a caller to scope the tag_publications to a user or
# a tag_group.
#
class TagPublicationsController < ApplicationController
  skip_before_filter :login_required, :only => :show
  skip_before_filter :load_view, :only => :show
  before_filter :find_base
  before_filter :convert_tag
  
  def index
    @tag_publications = @base.tag_publications
    
    respond_to do |wants|
      wants.html { render :action => 'index'}
      wants.xml  { render :xml => @tag_publications.to_xml }
    end
  end
  
  def show
    if @tag_publication = @base.tag_publications.find_by_tag_id(Tag.find_or_create_by_name(params[:id]).id)
      @feed_items = @tag_publication.find_feed_items(:limit => 20, :order => 'time desc')
    
      respond_to do |format|
        format.atom {render :action => 'show.rxml', :layout => false}
      end
    else
      render :text => "#{params[:id]} has not been published by #{@base.login}", :status => 404
    end
  end
  
  def new
    @tag_publication = @base.tag_publications.build(params[:tag_publication])
    
    respond_to do |wants|
      if TagGroup.count.zero?
        flash[:error] = "No Tag Groups exist so you can't publish a tag."
        wants.html { redirect_to :back }
        wants.js   { headers['Content-Type'] = 'text/html'; render :inline => '<%= show_flash %>', :status => 500; flash.discard }
      else
        wants.html
        wants.js   { headers['Content-Type'] = 'text/html'; render :partial => 'form' }
      end
    end
  end
  
  def create
    @tag_publication = @base.tag_publications.build(params[:tag_publication])
    
    respond_to do |wants|
      if @tag_publication.save
        @tag_publication.classifier.start_background_classification rescue logger.warn($!)
        flash[:notice] = "#{@tag_publication.tag} successfully published to #{@tag_publication.tag_group.name}"
      else
        flash[:error] = "Could not publish tag: #{@tag_publication.errors.full_messages.join(', ')}."
      end
      wants.html {redirect_to :back}
    end
  end
  
  def destroy
    publication = @base.tag_publications.find(params[:id])
    
    case @base
    when TagGroup
      if @base.global? and current_user.has_role?('admin')
        publication.destroy if publication
        flash[:notice] = "Tag Publication Deleted"
      end
    when User
      if publication and current_user == @base
        publication.destroy 
        flash[:notice] = "Published Tag Deleted"
      else
        flash[:warning] = "You aren't allow to delete another users tag"
      end
    end
    
    redirect_to :back
  end
  
  private
  def find_base
    if params[:tag_group_id]
      @base = @tag_group = TagGroup.find(params[:tag_group_id])
    elsif params[:user_id]
      @base = @user = User.find_by_login(params[:user_id])
    end
  end
  
  def convert_tag
    if params[:tag_publication] and params[:tag_publication][:tag].is_a?(String)
      params[:tag_publication][:tag] = Tag.find_or_create_by_name(params[:tag_publication][:tag])
    end
  end
end