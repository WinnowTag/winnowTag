# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
class FeedsController < ApplicationController
  include CollectionJobResultsHelper
  include ActionView::Helpers::TextHelper
  permit 'admin', :only => [:import, :update]  
  verify :only => :show, :params => :id, :redirect_to => {:action => 'index'}
  before_filter :setup_search_term, :only => [:index]
  before_filter :flash_collection_job_result
  
  def index
    respond_to do |wants|
      wants.html do
        add_to_sortable_columns('feeds', :model => Feed, :field => 'title', :alias => 'title')
        add_to_sortable_columns('feeds', :field => 'feed_items_count', :alias => 'item_count')
        add_to_sortable_columns('feeds', :field => 'updated_on', :alias => 'updated_on')
        
        @feed_pages = Paginator.new(self, Feed.count(:conditions => @conditions), 40, params[:page])
        @feeds = Feed.find(:all,
                            :conditions => @conditions,
                            :limit => @feed_pages.items_per_page, 
                            :offset => @feed_pages.current.offset,
                            :order => sortable_order('feeds', 
                                                    :model => Feed, 
                                                    :field => 'title', 
                                                    :sort_direction => :asc))
      end
      wants.xml { render :xml => Feed.find(:all).to_xml }
    end
  end
  
  def new
    @feed = Feed.new
  end
  
  def create
    @feed = Remote::Feed.new(params[:feed])
    respond_to do |wants|
      if @feed.save
        @collection_job = @feed.collect(:created_by => current_user.login, 
                                        :callback_url => collection_job_results_url(current_user))
        wants.html do
          flash[:notice] = "Added feed from '#{@feed.url}'. " +
                           "Collection has been scheduled for this feed, " +
                           "we'll let you know when it's done."
          redirect_to feeds_url
        end
      else
        wants.html { render :action => 'new' }
      end
    end    
  end
  
  def show
    @feed = Feed.find(params[:id])
  end  

  def auto_complete_for_feed_title
    @q = params[:feed][:title]
    
    conditions = ["LOWER(title) LIKE LOWER(?)"]
    values = ["%#{@q}%"]
    
    if !@view.feed_filter.values.flatten.blank?
      conditions << "id NOT IN (?)"
      values << @view.feed_filter.values.flatten
    end
    
    @feeds = Feed.find(:all, :conditions => [conditions.join(" AND "), *values])
    render :layout => false
  end

  private
  def setup_search_term
    @search_term = params[:search_term]
    unless @search_term.nil? or @search_term.empty?
      @conditions = ['title like ? or url like ?', "%#{@search_term}%", "%#{@search_term}%"]
    end
  end
end
