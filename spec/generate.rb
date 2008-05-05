class Generate
  def self.comment(attributes = {})
    Comment.new(:tag_id => 1, :user_id => 1, :body => "Example body")
  end
end