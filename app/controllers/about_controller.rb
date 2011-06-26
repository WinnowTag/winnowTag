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


# The +AboutController+ is publically accessible and does not require any
# user to be logged in.
class AboutController < ApplicationController
  skip_before_filter :login_required
  skip_before_filter :check_if_user_must_update_password
  around_filter :no_logging, :only => :info

  # The +index+ action displays information about the version of Winnow
  # and the version of the Classifier it is communicating with.
  def index
    # Capistrano now stores the revision in RAILS_ROOT/REVISION
    cap_rev_file = File.join(RAILS_ROOT, 'REVISION')

    if File.exists?(cap_rev_file)
      @revision = File.read(cap_rev_file)
    else
      @revision = `git rev-parse --short HEAD`.chomp
    end

    begin
      @classifier_info = Remote::Classifier.get_info
    rescue
      @classifier_info = nil
    end
  end

private
  
  def no_logging
    logger.silence do
      yield
    end
  end
end
