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

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/about' do
  before(:each) do
    @classifier_info = mock_model(Remote::Classifier)
    assigns[:classifier_info] = @classifier_info
  end
  
  it "should display svn version" do
    @classifier_info.should_receive(:version).once.and_return("1.0")
    @classifier_info.should_receive(:git_revision).once.and_return("2808")
    
    render "/about/index"
    
    response.should have_text(/1\.0/)
    response.should have_text(/2808/)
  end
  
  it "should display classifier error when classifier_info is nil" do
    assigns[:classifier_info] = nil    
    render "/about/index"
    response.should have_tag("p.classifier_error", "Winnow could not be contacted.")
  end
end