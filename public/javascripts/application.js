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
  
  $$("table.recordset").each(function(table) {
    Table.stripe(table);
  });
});

var Table = {
  stripe: function(table) {
    table = $(table);
    var skip = parseInt(table.getAttribute("skip")) || 1;
    var next = skip;
    var className = "odd";
    var first = true;
    table.select("tr").each(function(element) {
      element.removeClassName("odd");
      element.removeClassName("even");
      if(first) {
        first = false;
        return;
      } else if(next == 0) {
        className = (className == "odd" ? "even" : "odd");
        next = skip - 1;
      } else {
        next -= 1;
      }
      element.addClassName(className);
    });
  }
}

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
	if(content && (!Prototype.Browser.IE || content.tagName != 'TBODY')) {
		var body_height = $(document.body).getHeight();
		var top_of_content = content.offsetTop;
		var content_padding = parseInt(content.getStyle("padding-top")) + parseInt(content.getStyle("padding-bottom"));
    var footer_height = $('footer') ? $('footer').getHeight() : 0;
		var feed_item_height = body_height - top_of_content - footer_height - content_padding;
		content.style.height = feed_item_height + 'px';
		
	  var sidebar = $('sidebar');
		if(sidebar) {
		  var sidebar_padding = parseInt(sidebar.getStyle("padding-top")) + parseInt(sidebar.getStyle("padding-bottom"));
		  var sidebar_height = body_height - top_of_content - sidebar_padding;
			sidebar.style.height = sidebar_height + 'px';
			$('sidebar_control').style.height = (sidebar_height + sidebar_padding) + 'px';
		}
	}
}

function toggleSidebar() {
  var sidebar = $('sidebar');
  var sidebar_control = $('sidebar_control');
  sidebar.toggle();
  if(sidebar.visible()) {
    sidebar_control.addClassName('open');
    Cookie.set("show_sidebar", "true", 365);
  } else {
    sidebar_control.removeClassName('open');
    Cookie.set("show_sidebar", "false", 365);
  }
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
