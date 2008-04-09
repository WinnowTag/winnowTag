class FeedsPresenter < Presenter
  attr_accessor :search_term, :page, :order
  
  def feeds
    @feeds ||= Feed.search :search_term => search_term, :excluder => current_user, :page => page, :order => order
  end
end