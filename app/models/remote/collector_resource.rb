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

module Remote
  # This is a base class used to define the configuration necessary to 
  # communicate with the collector.
  class CollectorResource < ActiveResource::Base
    with_auth_hmac(HMAC_CREDENTIALS['winnow'])
    
    begin
      self.site = File.read(File.join(RAILS_ROOT, 'config', 'collector.conf'))
    rescue
      self.site = "http://collector.mindloom.org"
    end
    
    def self.with_redirect(limit = 5)      
      begin
        yield
      rescue ActiveResource::Redirection => redirect
        raise redirect if limit < 0
        # try and get the id
        if id = redirect.response['Location'][/\/([^\/]*?)(\.\w+)?$/, 1]
          with_redirect(limit - 1) do
            self.find(id)
          end
        else
          raise ActiveResource::RecordNotFound, redirect.response
        end
      end
    end
  end
end