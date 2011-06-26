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

module WinnowMatchers
  class KaphanHeaderMatcher
    def initialize(comment_line, comment_start = nil, comment_end = nil)
      @header = <<-EOHEADER
#{comment_start || comment_line} General info: http://doc.winnowtag.org/open-source
#{comment_line} Source code repository: http://github.com/winnowtag
#{comment_line} Questions and feedback: contact@winnowtag.org
#{comment_line}
#{comment_line} Copyright (c) 2007-2011 The Kaphan Foundation
#{comment_line}
#{comment_line} Permission is hereby granted, free of charge, to any person obtaining a copy
#{comment_line} of this software and associated documentation files (the "Software"), to deal
#{comment_line} in the Software without restriction, including without limitation the rights
#{comment_line} to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#{comment_line} copies of the Software, and to permit persons to whom the Software is
#{comment_line} furnished to do so, subject to the following conditions:
#{comment_line}
#{comment_line} The above copyright notice and this permission notice shall be included in
#{comment_line} all copies or substantial portions of the Software.
#{comment_line}
#{comment_line} THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#{comment_line} IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#{comment_line} FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#{comment_line} AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#{comment_line} LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#{comment_line} OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#{comment_line} THE SOFTWARE.
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
