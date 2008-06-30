# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class MessagesController < ApplicationController
  def index
    @messages = Message.find_global
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
      flash[:notice] = _(:message_created)
      redirect_to messages_path
    else
      render :action => "new"
    end
  end

  def update
    @message = Message.find(params[:id])

    if @message.update_attributes(params[:message])
      flash[:notice] = _(:message_updated)
      redirect_to messages_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @message = Message.destroy(params[:id])
    redirect_to messages_path
  end
  
  def mark_read
    if params[:id]
      Message.mark_read_for(current_user.id, params[:id])
    else
      Message.mark_read_for(current_user.id)
    end
    respond_to :js
  end
end
