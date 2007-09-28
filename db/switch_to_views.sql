drop table if exists feeds, feed_items, feed_item_contents, feed_item_xml_data, feed_xml_datas, feed_item_tokens_containers, random_backgrounds, tokens;
create or replace algorithm=merge view feeds as select * from collector.feeds;
create or replace algorithm=merge view feed_items as select * from collector.feed_items;
create or replace algorithm=merge view feed_item_contents as select * from collector.feed_item_contents;
create or replace algorithm=merge view feed_item_xml_data as select * from collector.feed_item_xml_data;
create or replace algorithm=merge view feed_xml_datas as select * from collector.feed_xml_datas;
create or replace algorithm=merge view feed_item_tokens_containers as select * from collector.feed_item_tokens_containers;
create or replace algorithm=merge view random_backgrounds as select * from collector.random_backgrounds;
create or replace algorithm=merge view tokens as select * from collector.tokens;

