# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class InvitesController < ApplicationController
  permit 'admin'
  
  def index
    respond_to do |format|
      format.html
      format.js do
        limit = (params[:limit] ? [params[:limit].to_i, MAX_LIMIT].min : DEFAULT_LIMIT)
        @invites = Invite.search(:text_filter => params[:text_filter], :order => params[:order], :direction => params[:direction],
                                 :limit => limit, :offset => params[:offset])
        @full = @invites.size < limit
      end
    end
  end

  def new
    @invite = Invite.new
  end
  
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
  def activate?
    params[:activate] =~ /true/i
  end
end
