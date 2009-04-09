class PublicController < ApplicationController
  skip_before_filter :login_required

  def ie6
    render :template => "public/ie6", :layout => "ie6"
  end
end