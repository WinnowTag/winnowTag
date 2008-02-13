# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class InvitesController < ApplicationController
  permit 'admin'
  
  def index
    @invites = Invite.search(:q => params[:q], :per_page => 30, :page => params[:page])
  end

  def new
    @invite = Invite.new
  end
  
  def create
    @invite = Invite.new(params[:invite])
    @invite.save!
    if activate?
      @invite.activate!
      UserNotifier.deliver_invite_accepted(@invite, login_url(:invite => @invite.code))
    end
    redirect_to invites_path
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @invite = Invite.find(params[:id])
  end
  
  def update
    @invite = Invite.find(params[:id])
    @invite.update_attributes! params[:invite]
    if activate?
      @invite.activate!
      UserNotifier.deliver_invite_accepted(@invite, login_url(:invite => @invite.code))
    end
    redirect_to invites_path
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end
  
  def activate
    @invite = Invite.find(params[:id])
    @invite.activate!(params[:invite])
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
