module Fiveruns::Manage::Targets::Rails::ActionView
  
  module PartialTemplate

    def self.included(base)
      Fiveruns::Manage.instrument base, InstanceMethods
    end
    
    def self.relevant?
      Fiveruns::Manage::Version.rails < Fiveruns::Manage::Version.new(2,1,0) ? false : true
    end

    module InstanceMethods
      def render_with_fiveruns_manage(*args, &block)
        Fiveruns::Manage::Targets::Rails::ActionView::Base.record path do
          render_without_fiveruns_manage(*args, &block)
        end
      end
    end
    
  end

end