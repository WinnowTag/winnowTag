class ViewTagState < ActiveRecord::Base
  belongs_to :view
  belongs_to :tag
end
