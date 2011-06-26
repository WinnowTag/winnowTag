# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# Represents a User subscribing to a Tag. In other words, the User wants
# to see content from this Tag.
class TagSubscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag
  
  validates_presence_of :user_id, :tag_id

  def tag_archived(original_creator)
    update_attribute(:original_creator, original_creator);
    update_attribute(:original_creator_timestamp, Time.now.utc);
  end

  def tag_renamed(old_name, new_name)
    if !original_name
      update_attribute(:original_name, old_name);
      update_attribute(:original_name_timestamp, Time.now.utc);
    elsif original_name == new_name
      clear_original_name;
    end
  end

  def clear_original_creator
    update_attribute(:original_creator, nil);
    update_attribute(:original_creator_timestamp, nil);
  end

  def clear_original_name
    update_attribute(:original_name, nil);
    update_attribute(:original_name_timestamp, nil);
  end
end
