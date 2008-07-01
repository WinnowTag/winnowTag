# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
#

module Remote
  class ClassifierClues
    def self.find_by_item_id_and_tag_url(item_id, tag_url)
      # require 'md5'
      # clues = []
      # 101.times do |i|
      #   clues << { 'prob' => rand.round(6), 'clue' => "t:#{MD5.hexdigest(rand.to_s)[0..rand(16)]}" }
      # end
      # return clues

      url = build_clue_url(item_id, tag_url)      
      response = Net::HTTP.get_response(url)
      ActiveRecord::Base.logger.debug "fetching clues from #{build_clue_url(item_id, tag_url)}"

      if response.code == "200"
        return ActiveSupport::JSON.decode(response.body)
      elsif response.code == "424"
        return :redirect
      else
        return nil
      end
    end
    
    def self.build_clue_url(item_id, tag_url)
      URI.parse(Remote::ClassifierResource.site.to_s + "/clues?" +
                  "tag=#{URI.escape(tag_url)}" +
                  "&item=#{URI.escape("urn:peerworks.org:entry##{item_id}")}")
    end
  end
end
