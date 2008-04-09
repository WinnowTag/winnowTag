class MessagesController < ApplicationController
  def index
    @messages = Message.find_global
  end

  def show
    @message = Message.find(params[:id])
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
      flash[:notice] = 'Message was successfully created.'
      redirect_to(@message)
    else
      render :action => "new"
    end
  end

  def update
    @message = Message.find(params[:id])

    if @message.update_attributes(params[:message])
      flash[:notice] = 'Message was successfully updated.'
      redirect_to(@message)
    else
      render :action => "edit"
    end
  end

  def destroy
    @message = Message.destroy(params[:id])
    redirect_to(messages_url)
  end
end
