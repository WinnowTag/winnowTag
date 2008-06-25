// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please contact info@peerworks.org for further information.
function exceptionToIgnore(e) {
  // Ignore this Firefox error because it just occurs when a XHR request is interrupted.
  return e.name == "NS_ERROR_NOT_AVAILABLE"
}

Position.includeScrollOffsets = true;

document.observe('dom:loaded', function() {
  $$("input.example[type=text]").each(function(element) {
    var example_value = element.value;
    element.observe("focus", function() {
      if(element.value == example_value) {
        element.value = "";
        element.removeClassName("example");
      }
    });
    element.observe("blur", function() {
      if(element.value == "") {
        element.value = example_value;
        element.addClassName("example");
      }
    });
  });
});

/** Ajax Responders to Handle time outs of Ajax requests */
Ajax.Responders.register({
	onCreate: function(request) {
		request.timeoutId = window.setTimeout(function() {
			var state = Ajax.Request.Events[request.transport.readyState];
			
			if (!['Uninitialized', 'Complete'].include(state)) {				
				if (request.options.onTimeout) {
					request.options.onTimeout(request.transport, request.json);
				} else {
					request.timeout_message = new TimeoutMessage(request);
				}				
			}
		}, 10000);
	},
	onComplete: function(request) {
		if (request.timeout_message) {
			request.timeout_message.clear();			
		}
	}
});

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

function escape_javascript(string) {
  return string.replace(/'/g, '\\\'');
}
  
Effect.ScrollToInDiv = Class.create(Effect.Base, {
  initialize: function(container, element) {
    this.container = $(container);
    this.element = $(element);
    this.bottom_margin = (arguments[2] && arguments[2].bottom_margin) || 0;
    this.start(arguments[2] || {});      
  },
  setup: function() {
    var containerOffset = Position.cumulativeOffset(this.container);
    var offsets = Position.cumulativeOffset(this.element);
    if(this.options.offset) {
      offsets[1] += this.options.offset;
    }

    this.scrollStart = this.container.scrollTop;
     var top_of_element = offsets[1] - this.scrollStart;
     var top_of_container = containerOffset[1];
     var bottom_of_element = offsets[1] + this.element.getHeight() - this.scrollStart;
     var bottom_of_container = containerOffset[1] + this.container.getHeight();
     
     // If the item is above the top of the container, or the item is taller than the container, scroll to the top of the item
     if(top_of_element < top_of_container || this.element.getHeight() > this.container.getHeight()) {
       this.delta = top_of_element - top_of_container;

     // If the item is below the bottom of the container, scroll to the bottom of the item
     } else if(bottom_of_element > bottom_of_container) {
       this.delta = bottom_of_element - bottom_of_container + this.bottom_margin;

     } else {
       this.delta = 0;
     }
  },
  update: function(factor) {
    this.container.scrollTop = this.scrollStart + (factor * this.delta);
  }
});