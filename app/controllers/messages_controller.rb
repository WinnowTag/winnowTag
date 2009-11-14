# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

# The +MessagesController+ is only accessible by admin users. Admins use
# this controller to create global messages that all users will see.
class MessagesController < ApplicationController
  permit 'admin'
  
  def index
    @messages = Message.global
  end
  
  def new
    @message = Message.new
  end

  def edit
    @message = Message.find(params[:id])
  end

  def create
    @message = Message.new(params[:message])

    if @message.save
      flash[:notice] = t("winnow.notifications.message_created")
      redirect_to messages_path
    else
      render :action => "new"
    end
  end

  def update
    @message = Message.find(params[:id])

    if @message.update_attributes(params[:message])
      flash[:notice] = t("winnow.notifications.message_updated")
      redirect_to messages_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @message = Message.destroy(params[:id])
    redirect_to messages_path
  end
end
