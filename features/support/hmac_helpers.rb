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


def get_with_hmac(url, params = {}, headers = {})
  request = Net::HTTP::Get.new(URI.parse(url).path, {'Content-Type' => "application/x-www-form-urlencoded"}.merge(headers))
  AuthHMAC.sign!(request, 'classifier_id', 'classifier_secret')
  sent_headers = headers.merge({'Authorization' => request['Authorization'], 'Date' => request['Date']})
  get url, params, sent_headers
end

def post_with_hmac(url, data, headers)
  request = Net::HTTP::Post.new(URI.parse(url).path, headers)
  AuthHMAC.sign!(request, 'collector_id', 'collector_secret')
  sent_headers = headers.merge({'Authorization' => request['Authorization'], 'Date' => request['Date']})
  post url, data, sent_headers
end

def put_with_hmac(url, data, headers)
  request = Net::HTTP::Put.new(URI.parse(url).path, headers)
  AuthHMAC.sign!(request, 'collector_id', 'collector_secret')
  sent_headers = headers.merge({'Authorization' => request['Authorization'], 'Date' => request['Date']})
  put url, data, sent_headers
end

def delete_with_hmac(url, params, headers)
  request = Net::HTTP::Delete.new(URI.parse(url).path, {'Content-Type' => "application/x-www-form-urlencoded"}.merge(headers))
  AuthHMAC.sign!(request, 'collector_id', 'collector_secret')
  sent_headers = headers.merge({'Authorization' => request['Authorization'], 'Date' => request['Date']})
  delete url, params, sent_headers
end
