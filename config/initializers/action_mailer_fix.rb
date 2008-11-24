module ActionMailer
  class Base
    def render_message(method_name, body)
      if method_name.respond_to?(:content_type) && !method_name.is_a?(String)
        @current_template_content_type = method_name.content_type
      end
      render :file => method_name, :body => body
    ensure
      @current_template_content_type = nil
    end
  end
end