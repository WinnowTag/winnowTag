begin;
insert into demo.feed_items select *, NULL from collector.feed_items where content_length > 750 order by time DESC limit 60000;
insert into demo.feeds select distinct collector.feeds.* from collector.feeds inner join demo.feed_items on demo.feed_items.feed_id = collector.feeds.id;
insert into feed_item_contents select distinct collector.feed_item_contents.* from collector.feed_item_contents inner join demo.feed_items on collector.feed_item_contents.feed_item_id = demo.feed_items.id;
insert into feed_item_xml_data select collector.feed_item_xml_data.* from collector.feed_item_xml_data inner join demo.feed_items on collector.feed_item_xml_data.id = demo.feed_items.id;
insert into feed_xml_datas select collector.feed_xml_datas.* from collector.feed_xml_datas inner join demo.feeds on demo.feeds.id = collector.feed_xml_datas.id;

-- Remove feed items with less that 50 tokens 
delete from feed_item_xml_containers where distinct_token_count < 50;
delete from feed_items, feed_item_contents, feed_item_xml_data using feed_items inner join feed_item_contents on feed_items.id = feed_item_contents.feed_item_id inner join feed_item_xml_data on feed_items.id = feed_item_xml_data.id left outer join feed_item_tokens_containers on feed_items.id = feed_item_tokens_containers.feed_item_id where feed_item_tokens_containers.id is null;