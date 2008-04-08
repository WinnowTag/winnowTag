# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
class InvitesController < ApplicationController
  permit 'admin'
  
  def index
    add_to_sortable_columns('invites', :field => 'created_at')
    add_to_sortable_columns('invites', :field => 'email')
    add_to_sortable_columns('invites', :field => 'status')
      
    @invites = Invite.search(:q => params[:q], :per_page => 20, :page => params[:page], :order => "#{sortable_order('invites', :alias => 'created_at', :sort_direction => :asc)}")
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
