# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class GlobalTagGroupsController < ApplicationController
  permit 'admin'
  
  def index
    respond_to do |wants|
      @title = "Global Tag Groups"
      @global_tag_groups = TagGroup.find_globals
      wants.html # render index.rhtml
      wants.xml { render :xml => @global_tag_groups.to_xml}
    end
  end
  
  def new
    @title = "New Global Tag Group"
    @global_tag_group = TagGroup.new_global
  end
  
  def create
    respond_to do |wants|
      @global_tag_group = TagGroup.new_global(params[:global_tag_group])
      
      if @global_tag_group.save
        flash[:notice] = "Global Tag Group '#{@global_tag_group.name}' was created."
        wants.html {redirect_to global_tag_groups_url}
        wants.xml  {head :created, :location => global_tag_group_url(@global_tag_group)}
      else
        wants.html {render :action => "new"}
        wants.xml  {render :xml => @global_tag_group.errors.to_xml}
      end
    end
  end
  
  def destroy
    respond_to do |wants|
      TagGroup.find(params[:id]).destroy
      
      wants.html { redirect_to :back }
      wants.xml  { render :nothing => true }
    end
  end
  
  def set_tag_group_name
    respond_to do |wants|
      tag_group = TagGroup.find(params[:id])
      old_name = tag_group.name
      tag_group.name = params[:value]
    
      if tag_group.save
        wants.js { render :update do |page| 
          page.replace_html(tag_group.dom_id('name'), tag_group.name);
        end}
      else
        wants.js { render :update do |page|
          page << "new ErrorMessage('Can\\\'t update Tag Group name: #{tag_group.errors.full_messages.first}');"
          page.replace_html(tag_group.dom_id('name'), old_name);
        end}
      end
    end
  end
  
  def set_tag_group_description
    @tag_group = TagGroup.find(params[:id])
    @tag_group.description = params[:value]
    @tag_group.save
    render :inline => '<%=markdown @tag_group.description %>'
  end
  
  def description
    tag_group = TagGroup.find(params[:id])
    render :text => tag_group.description
  end
end