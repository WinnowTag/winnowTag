begin;
create temporary table temp_feed_items like feed_items;

insert into temp_feed_items select *, NULL from collector.feed_items where content_length > 750 and time > (select max(time) from feed_items);
insert into feed_item_contents select distinct collector.feed_item_contents.* from collector.feed_item_contents inner join temp_feed_items on collector.feed_item_contents.feed_item_id = temp_feed_items.id;
insert ignore into feed_item_xml_data select collector.feed_item_xml_data.* from collector.feed_item_xml_data inner join temp_feed_items on collector.feed_item_xml_data.id = temp_feed_items.id;
insert ignore into feed_items select * from temp_feed_items;
