# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
#

module Remote
  class ClassifierClues
    def self.find_by_item_id_and_tag_url(item_id, tag_url)
      # clues = []
      # 101.times do |i|
      #   clues << { 'prob' => rand.round(6), 'clue' => "t:#{MD5.hexdigest(rand.to_s)[0..rand(16)]}" }
      # end
      # return clues
      access_id = HMAC_CREDENTIALS['winnow'].keys.first
      secret_key = HMAC_CREDENTIALS['winnow'].values.first
      
      url = build_clue_url(item_id, tag_url)
      request = Net::HTTP::Get.new(url.request_uri)
      
      if access_id && secret_key
        AuthHMAC.sign!(request, access_id, secret_key)
      end
      
      response = nil
      Net::HTTP.start(url.host, url.port) do |http|
        response = http.request(request)
      end
      ActiveRecord::Base.logger.debug "fetching clues from #{build_clue_url(item_id, tag_url)}"

      if response.code == "200"
        return ActiveSupport::JSON.decode(response.body)
      elsif response.code == "424"
        return :redirect
      else
        return nil
      end
    rescue Errno::ECONNREFUSED
      return nil
    end
    
    def self.build_clue_url(item_id, tag_url)
      URI.parse(Remote::ClassifierResource.site.to_s + "/clues?" +
                  "tag=#{URI.escape(tag_url)}" +
                  "&item=#{URI.escape("urn:peerworks.org:entry##{item_id}")}")
    end
  end
end
