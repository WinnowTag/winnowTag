xml.instruct!

xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do

  xml.title   @tag.name
  xml.link    "rel" => "self", "href" => public_tag_url(@tag.user, @tag)
  xml.id      public_tag_url(@tag.user, @tag)
  xml.updated @tag.feed_items.first.updated.strftime("%Y-%m-%dT%H:%M:%SZ") if @tag.feed_items.any?
  

  @tag.feed_items.find(:all, :include => [:feed, :content], :order => "feed_items.updated DESC", :limit => 50).each do |feed_item|
    xml.entry do
      xml.title feed_item.title
      xml.author  do
        xml.name feed_item.feed.title
        xml.uri  feed_item.feed.alternate
      end
      xml.link    "href" => feed_item.link, "rel" => "alternate"
      xml.id      feed_item_url(feed_item)
      xml.updated feed_item.updated.strftime("%Y-%m-%dT%H:%M:%SZ")
      if feed_item.content.content
        xml.content "type" => "html" do
          xml.text! %Q(<strong>Sourced from: <a href="#{feed_item.feed.alternate}">#{feed_item.feed.title}</a></strong><br/><br/>)
          xml.text! feed_item.content.content
        end
      end
    end
  end
end
