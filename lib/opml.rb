# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require 'xml/libxml'

class Opml
  def self.parse(io)    
    case io
    when IO     then new(XML::Parser.io(io).parse)
    when String then new(XML::Parser.string(io).parse)
    else
      raise ArgumentError, "Dont know how to parse a #{io.class.name}"
    end
  end
  
  def initialize(document)
    @document = document
  end
  
  def feeds
    @document.find("/opml/body/outline[@xmlUrl]").map do |e|
      Feed.new(e)
    end
  end
  
  def inspect
    "<OPML>"
  end
  
  class Feed
    def initialize(element)
      @element = element
    end
    
    [:title, :xmlUrl].each do |m|
      define_method(m) do
        @element[m.to_s]
      end
    end    
  end
end
