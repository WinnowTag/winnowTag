require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do
  describe "validations" do
    it "validates presence of user id" do
      Generate.comment.should validate(:user_id, [1], [nil])
    end

    it "validates presence of tag id" do
      Generate.comment.should validate(:tag_id, [1], [nil])
    end

    it "validates presence of body" do
      Generate.comment.should validate(:body, ["Example Body"], [nil, ""])
    end
  end
end
