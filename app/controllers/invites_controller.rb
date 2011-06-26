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


# The +InvitesController+ is only accessible by admin users. Admins use
# this controller create/activate invitations as well as customize the 
# email subject/body that gets sent to the user when the invitation
# is activated.
class InvitesController < ApplicationController
  permit 'admin'
  
  # See FeedItemsController#index for an explanation of the html/json requests.
  def index
    respond_to do |format|
      format.html
      format.json do
        @invites = Invite.search(:text_filter => params[:text_filter], :order => params[:order], :direction => params[:direction],
                                 :limit => limit, :offset => params[:offset])
        @full = @invites.size < limit
      end
    end
  end

  def new
    @invite = Invite.new
  end
  
  # The +create+ action will send an email the invitee if the 
  # invitation was activated.
  def create
    @invite = Invite.new(params[:invite])
    if @invite.save
      if activate?
        @invite.activate!
        UserNotifier.deliver_invite_accepted(@invite, login_url(:invite => @invite.code))
      end
      redirect_to invites_path
    else
      render :action => 'new'
    end
  end

  def edit
    @invite = Invite.find(params[:id])
  end
  
  # The +update+ action will send an email the invitee if the 
  # invitation was activated.
  def update
    @invite = Invite.find(params[:id])
    if @invite.update_attributes(params[:invite])
      if activate?
        @invite.activate!
        UserNotifier.deliver_invite_accepted(@invite, login_url(:invite => @invite.code))
      end
      redirect_to invites_path
    else
      render :action => 'edit'
    end
  end
  
  # The +activate+ action will send an email the invitee letting them know
  # their invitation has been accepted and they can now signup for a Winnow
  # account.
  def activate
    @invite = Invite.find(params[:id])
    @invite.activate!
    UserNotifier.deliver_invite_accepted(@invite, login_url(:invite => @invite.code))
    redirect_to invites_path
  end
  
  def destroy
    Invite.destroy(params[:id])
    redirect_to invites_path
  end

private
  # The +activate?+ method returns a boolean denoting whether or not
  # the admin user checked the "Activate?" checkbox when creating/editing
  # an invitation. This is used to decide whether or not to activate the
  # invitation and send them an email letting them know their invitation 
  # has been accepted and they can now signup for a Winnow account.
  def activate?
    params[:activate] =~ /true/i
  end
end
