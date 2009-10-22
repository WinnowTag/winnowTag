# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.

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
