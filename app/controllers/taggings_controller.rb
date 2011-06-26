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


# Required for the +Tag()+ function.  Rails can sometimes auto-load this and
# sometimes it doesn't so lets put it here explicitly so we can always be
# sure it has been loaded and the +Tag()+ function is available.
# require 'tag.rb'

# Not explicitly requiring the file because is causes problems with reloading
# in development mode. Using this contstant allows rails to auto load the 
# +Tag+ class, and therefore the +Tag()+ function
Tag

# The +TaggingsController+ is used to manage user taggings on feed items.
class TaggingsController < ApplicationController
  # The +create+ action creates a single +Tagging+ for a 
  # <tt><FeedItem, User, Tag></tt> combination. Any existing
  # tagging for that combination will be deletd.
  def create
    tag = Tag(current_user, params[:tagging][:tag])
    @tagging = Tagging.new(params[:tagging].merge(:tag => tag, :user => current_user))
    # Save the tagging within a transaction to avoid errors from duplicate taggings
    if Tagging.transaction { @tagging.save }
      respond_to :json
    else
      respond_to do |format|
        format.json { render :action => "error.json.erb" }
      end
    end
  end
  
  # The +destroy+ action destroys a user tagging on a FeedItem.
  #
  # Accepted Parameters:
  #
  # - +tagging+:
  #   - +feed_item_id+: The id of a +FeedItem+ to destroy a +Tagging+ on.
  #   - +tag+:          The name of the +Tag+ to destroy the +Tagging+ on the +FeedItem+.
  def destroy
    @feed_item = FeedItem.find(params[:tagging][:feed_item_id])
    @tag = Tag(current_user, params[:tagging][:tag])
    
    current_user.taggings.find_by_feed_item(@feed_item, :all, 
      :conditions => { :classifier_tagging => false, :tag_id => @tag }).each(&:destroy)            

    respond_to :json
  end
end
