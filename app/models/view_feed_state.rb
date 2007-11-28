class ViewFeedState < ActiveRecord::Base
  belongs_to :view
  belongs_to :feed
  
  class << self
    def delete_all_for(feed, options = {})
      conditions, values, using = ["#{table_name}.feed_id = ?"], [feed], nil
      
      if options[:except] || options[:only]
        using = "views"
        conditions << "#{table_name}.view_id = views.id"
        if options[:except]
          conditions << "views.user_id != ?"
          values << options[:except]
        elsif options[:only]
          conditions << "views.user_id = ?"
          values << options[:only]          
        end
      end
      
      delete_all([conditions.join(" AND "), *values], using)
    end
    
    def delete_all(conditions = nil, using = nil)
      sql = "DELETE FROM #{table_name} "
      add_using!(sql, using)
      add_conditions!(sql, conditions, scope(:find))
      connection.delete(sql, "#{name} Delete all")
    end
    
    def add_using!(conditions, using)
      conditions << "USING #{table_name}, #{using} " unless using.blank?
    end
  end
end
