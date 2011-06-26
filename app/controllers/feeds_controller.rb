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


# The +FeedsController+ is used to manage the viewing and creation of feeds.
class FeedsController < ApplicationController

  # See FeedItemsController#index for an explanation of the html/json requests.
  def index
    respond_to do |format|
      format.html do
        # A new feed is instantiated here so it can be used on 
        # the Add/Import feed form.
        @feed = Remote::Feed.new(params[:feed] || {})
      end
      format.json do
        @feeds = Feed.search(:text_filter => params[:text_filter], :excluder => current_user,
                             :order => params[:order], :direction => params[:direction], 
                             :limit => limit, :offset => params[:offset])
        @full = @feeds.size < limit
      end
    end
  end

  # The +create+ action is used when a user requests a feed url to be added
  # to winnow. See FeedManager#create for more details on this creation process.
  def create
    creation = FeedManager.create(current_user, params[:feed][:url], collection_job_results_url(current_user))

    creation.success do |feed, notice|
      respond_to do |format|
        format.html do
          flash[:notice] = notice
          redirect_to feeds_path
        end
        format.js { @feed = feed }
      end
    end

    creation.failed do |feed, error|
      @feed = feed
      flash.now[:error] = error
      render :action => 'index'
    end
  end

  # The +import+ action is used to import an OPML file of feed urls.
  # This is done by communicateing with the Collector via the
  # +Remote::Feed+ model.
  # 
  # A collection request is sent to the Collector for each of the 
  # imported feeds.
  # 
  # A FeedSubscription is created for each Feed and the logged in user.
  MAX_IMPORT_FEEDS = 100
  def import
    the_opml = params[:opml].read
    begin
      feed_count = Opml.parse(the_opml).feeds.size
    rescue
      flash[:error] = t("winnow.notifications.bad_OPML_file")
    else
      if feed_count == 0
        flash[:error] = t("winnow.notifications.no_feeds_to_import")
      else
        if current_user.has_role?('admin') || feed_count <= MAX_IMPORT_FEEDS
          @feeds = Remote::Feed.import_opml(the_opml, current_user.login)

          @feeds.each do |feed|
            feed.collect(:created_by => current_user.login, :callback_url => collection_job_results_url(current_user))
          end

          flash[:stay_notice] = t("winnow.notifications.feeds_imported", :count => @feeds.size)
        else
          flash[:error] = t("winnow.notifications.too_many_feeds_to_import", :count => feed_count, :maximum => MAX_IMPORT_FEEDS)
        end
      end
    end
    redirect_to feeds_url
  end

  # The +globally_exclude+ action is used to add/remove a feed from a users
  # list of feed exlucsions.
  def globally_exclude
    @feed = Feed.find(params[:id])
    if params[:globally_exclude] =~ /true/i
      FeedExclusion.find_or_create_by_feed_id_and_user_id(@feed.id, current_user.id)
    else
      FeedExclusion.delete_all :feed_id => @feed.id, :user_id => current_user.id
    end
    respond_to :js
  end
end
