// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.

// This is needed for the sidebar drag/drop
Position.includeScrollOffsets = true;

function update_feed_filters(element, value) {
  element.value = "";
  if(value.match("#add_new_feed")) {
    new Ajax.Request("/feeds", {parameters: 'feed[url]='+encodeURIComponent(value.getAttribute("url")), method:'post'});
  } else {
    value.removeClassName('selected');
    insert_in_order('feed_filters', 'li', '.name', value, $(value).down(".name").innerHTML.unescapeHTML());
  	new Draggable(value.getAttribute("id"), {constraint:'vertical', ghosting:true, revert:true, reverteffect:function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }, scroll:'sidebar'});
    itemBrowser.toggleSetFilters({feed_ids: $(value).getAttribute("id").gsub("feed_", "")});
  	new Ajax.Request(value.getAttribute("subscribe_url"), {method:'put'});
  }
}

function update_tag_filters(element, value) {
  element.value = "";
  if(value.match("#add_new_tag")) {
    new Ajax.Request("/tags", {parameters: 'name='+encodeURIComponent(value.getAttribute("name")), method:'post'});
  } else {
    value.removeClassName('selected');
    insert_in_order('tag_filters', 'li', '.name', value, $(value).down(".name").innerHTML.unescapeHTML());
  	new Draggable(value.getAttribute("id"), {constraint:'vertical', ghosting:true, revert:true, reverteffect:function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }, scroll:'sidebar'});
    itemBrowser.toggleSetFilters({tag_ids: $(value).getAttribute("id").gsub("tag_", "")});
  	new Ajax.Request(value.getAttribute("subscribe_url"), {method:'put'});
  }
}

function clear_auto_complete(element, list) {
  list.update('');
}

function insert_in_order(container, sibling_selector, sibling_value_selector, element_html, element_value) {
  var container = $(container);
  
	var inserted = false;
	container.select(sibling_selector).each(function(element) {
	  var value_element = element.down(sibling_value_selector);
		if(!inserted && value_element && value_element.innerHTML.unescapeHTML().toLowerCase() > element_value.toLowerCase()) {
			new Insertion.Before(element, element_html);
			inserted = true;
		}
	});
	
	if(!inserted) {
		new Insertion.Bottom(container, element_html);
	}
}