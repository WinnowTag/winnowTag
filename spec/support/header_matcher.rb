# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module WinnowMatchers
  class KaphanHeaderMatcher
    def initialize(comment_line, comment_start = nil, comment_end = nil)
      @header = <<-EOHEADER
#{comment_start || comment_line} Copyright (c) 2008 The Kaphan Foundation
#{comment_line}
#{comment_line} Possession of a copy of this file grants no permission or license
#{comment_line} to use, modify, or create derivate works.
#{comment_line} Please visit http://www.peerworks.org/contact for further information.
EOHEADER
      @header << "#{comment_end}\n" if comment_end
      @header_size = @header.split(/\n/).size
    end

    def matches?(filename)
      @filename = filename
      @match = File.read(filename).match(/(?:.*\n){#{@header_size}}/)
      @match && @match[0] == @header
    end

    def failure_message
      "expected #{@filename} to have the header:\n#{@header}\nbut had the header:\n#{@match}"
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
