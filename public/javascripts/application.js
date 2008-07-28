// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.

// This is needed for the sidebar drag/drop
Position.includeScrollOffsets = true;

function exceptionToIgnore(e) {
  // Ignore this Firefox error because it just occurs when a XHR request is interrupted.
  return e.name == "NS_ERROR_NOT_AVAILABLE"
}

function resizeContent() {
  var content = $('content');
  var body_height = $(document.body).getHeight();
  var top_of_content = content.offsetTop;
  var content_padding = parseInt(content.getStyle("padding-top")) + parseInt(content.getStyle("padding-bottom"));
  var footer_height = $('footer') ? $('footer').getHeight() : 0;
  var container = $('container');
  var container_padding = parseInt(container.getStyle("padding-top")) + parseInt(container.getStyle("padding-bottom"));
  var feed_item_height = body_height - top_of_content - footer_height - content_padding - container_padding;
  content.style.height = feed_item_height + 'px';
  
  var sidebar = $('sidebar');
  var sidebar_control = $('sidebar_control');
  if(sidebar) {
    var sidebar_padding = parseInt(sidebar.getStyle("padding-top")) + parseInt(sidebar.getStyle("padding-bottom"));
    var sidebar_height = body_height - top_of_content - sidebar_padding + 3;
    sidebar.style.height = sidebar_height + 'px';
    sidebar_control.style.height = (sidebar_height + sidebar_padding) + 'px';
  }
  
  resizeContentWidth();
}

function resizeContentWidth() {
  var sidebar = $('sidebar');
  var sidebar_control = $('sidebar_control');

  var feed_item_width = $(document.body).getWidth();
  if(sidebar && sidebar.visible()) {
    var sidebar_margin = parseInt(sidebar.getStyle("margin-left")) + parseInt(sidebar.getStyle("margin-right"));
    feed_item_width = feed_item_width - sidebar.getWidth() - sidebar_margin;
  }
  if(sidebar_control) {
    var sidebar_control_margin = parseInt(sidebar_control.getStyle("margin-left")) + parseInt(sidebar_control.getStyle("margin-right"));
    feed_item_width = feed_item_width - sidebar_control.getWidth() - sidebar_control_margin;
    
  }

  var container = $('container');
  container.style.width = (feed_item_width - 7) + 'px';
}

(function() {
  var lastFontSize;
  
	if(window.getComputedStyle) {
		setInterval(function () {
			var currentFontSize = window.getComputedStyle(document.documentElement,null).fontSize;
			if( !lastFontSize || currentFontSize != lastFontSize ) {
				document.fire("font:resized");
				lastFontSize = currentFontSize;
			}
		}, 500);
	} else {
		// do the IE hackaround	
	}
})();

function update_feed_filters(element, value) {
  element.value = "";
  if(value.match("#add_new_feed")) {
    new Ajax.Request("/feeds", {parameters: 'feed[url]='+encodeURIComponent(value.getAttribute("url")), method:'post'});
  } else {
    value.removeClassName('selected');
    insert_in_order('feed_filters', 'li', '.name', value, $(value).down(".name").innerHTML);
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
    insert_in_order('tag_filters', 'li', '.name', value, $(value).down(".name").innerHTML);
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
		if(!inserted && value_element && value_element.innerHTML.toLowerCase() > element_value.toLowerCase()) {
			new Insertion.Before(element, element_html);
			inserted = true;
		}
	});
	
	if(!inserted) {
		new Insertion.Bottom(container, element_html);
	}
}
