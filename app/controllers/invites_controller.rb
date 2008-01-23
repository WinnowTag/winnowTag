# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class InvitesController < ApplicationController
  permit 'admin'
  
  def index
    @invites = Invite.paginate(:per_page => 30, :page => params[:page])
  end

  def new
    @invite = Invite.new
  end
  
  def create
    @invite = Invite.create!(params[:invite])
    if activate?
      @invite.activate!
      UserNotifier.deliver_invite_accepted(@invite, login_url(:invite => @invite.code))
    end
    redirect_to invites_path
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
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
