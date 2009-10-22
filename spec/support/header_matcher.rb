# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
module WinnowMatchers
  class KaphanHeaderMatcher
    def initialize(comment_line, comment_start = nil, comment_end = nil)
      @header = <<-EOHEADER
#{comment_start || comment_line} Copyright (c) 2008 The Kaphan Foundation
#{comment_line}
#{comment_line} Possession of a copy of this file grants no permission or license
#{comment_line} to use, modify, or create derivative works.
#{comment_line} Please visit http://www.peerworks.org/contact for further information.
EOHEADER
      @header << "#{comment_end}\n" if comment_end
    end

    def matches?(filename)
      @filename = filename
      File.read(filename).match(Regexp.new(Regexp.escape(@header))) ? true : false
    end

    def failure_message
      "expected #{@filename} to have the header:\n#{@header}"
    end
  end
  
  def have_ruby_kaphan_header
    KaphanHeaderMatcher.new("#")
  end
  
  def have_javascript_kaphan_header
    KaphanHeaderMatcher.new("//")
  end
  
  def have_stylesheet_kaphan_header
    KaphanHeaderMatcher.new(" *", "/*", " */")
  end
end
