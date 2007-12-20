module UrlWithViewId
  def self.included(base)
    base.alias_method_chain :url_for, :view_id
  end
  
  def url_for_with_view_id(options = {})
    if @view
      if options.kind_of? Hash
        options = { :view_id => @view.id }.update(options.symbolize_keys)
      elsif options.kind_of? String
        unless options.include?("view_id=")
          if options.include?("?")
            options << "&view_id=#{@view.id}"
          else
            options << "?view_id=#{@view.id}"
          end
        end
      end
    end
    
    url_for_without_view_id(options)
  end
end
ActionView::Base.send :include, UrlWithViewId
ActionController::Base.send :include, UrlWithViewId