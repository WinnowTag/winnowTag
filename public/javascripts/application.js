Position.includeScrollOffsets = true;

var errorTimeout = null;
var ErrorMessage = Class.create();
ErrorMessage.prototype = {
	initialize: function(message) {
		if (errorTimeout) {
			clearTimeout(errorTimeout);
		}
		this.error_message = $('error');
		this.error_message.update(message);
		this.error_message.show();
		
		resizeContent();

		self = this;
		errorTimeout = setTimeout(function() { 
			new Effect.Fade(self.error_message, {duration: 4, afterFinish: resizeContent});
		}, 10000);
	}	
};

var timeout_id = 1;
var TimeoutMessage = Class.create();
TimeoutMessage.prototype = {
  initialize: function(ajax) {
    this.timeout_id = timeout_id++;
    this.error_message = $('error');
    this.ajax = ajax;
    
    if (this.error_message) {
      this.error_message.update("The server is taking a while to repond. " + 
                                "We'll keep trying but you can " +
                                "<a href=\"#\" id=\"timeout" + this.timeout_id + "\">cancel</a>" +
                                " if you like.");
      Event.observe("timeout" + this.timeout_id, 'click', this.cancel.bindAsEventListener(this));
      this.error_message.show();
      resizeContent();
    }
  },
  
  clear: function() {
    this.error_message.hide();
    resizeContent();
  },
  
  cancel: function() {
    if (this.ajax) {      
			// disable the standard Prototype state change handle to avoid
			// confusion between timeouts and exceptions
      this.ajax.transport.onreadystatechange = Prototype.emptyFunction;
      this.ajax.transport.abort();
      
      if (this.ajax.options.onComplete && !(this.ajax instanceof Ajax.Updater)) {
				this.ajax.options.onComplete(this.ajax.transport, this.ajax.json);
			}
    }
    
    this.clear();
  }
};

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
    Cookie.set("show_sidebar", true, 365);
  } else {
    sidebar_control.removeClassName('open');
    Cookie.set("show_sidebar", false, 365);
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
  value.removeClassName('selected');
	$('feed_filters').appendChild(value);
	new Draggable(value.getAttribute("id"), {constraint:'vertical', ghosting:true, revert:true, reverteffect:function(element, top_offset, left_offset) { new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0 }); }, scroll:'sidebar'});
	new Ajax.Request(value.getAttribute("subscribe_url"), {method:'put'});
}

function clear_auto_complete(element, list) {
  element.value = "";
	list.update('');
}

function insert_in_order(container, sibling_selector, sibling_value_selector, element_html, element_value) {
  var container = $(container);
  
	var inserted = false;
	container.select(sibling_selector).each(function(element) {
		if(!inserted && element.down(sibling_value_selector).innerHTML.toLowerCase() > element_value.toLowerCase()) {
			new Insertion.Before(element, element_html + " ");
			inserted = true;
		}
	});
	
	if(!inserted) {
		new Insertion.Bottom(container, " " + element_html);
	}
}


var applesearch;
if (!applesearch)	applesearch = {};

applesearch.init = function () {
	if (navigator.userAgent.toLowerCase().indexOf('safari') < 0) {
		$$(".applesearch").each(function(element) {
		  element.addClassName("non_safari");
		  
		  var text_input = element.down("input");
		  var clear_button = element.down('.srch_clear');
		  Event.observe(text_input, 'keyup', function() {
		    applesearch.onChange(text_input, clear_button);
	    });
		  Event.observe(text_input, 'focus', function() {
		    applesearch.removePlaceholder(text_input);
	    });
		  Event.observe(text_input, 'blur', function() {
		    applesearch.insertPlaceholder(text_input);
	    });
		  Event.observe(clear_button, 'click', function() {
		    applesearch.clearFld(text_input, clear_button);
	    });
	    
      applesearch.onChange(text_input, clear_button);
      applesearch.insertPlaceholder(text_input);
		});
	}
}

applesearch.onChange = function (fld, btn) {
	if (fld.value.length > 0 && !btn.hasClassName("clear_button")) {
	  btn.addClassName("clear_button");
	} else if (fld.value.length == 0 && btn.hasClassName("clear_button")) {
	  btn.removeClassName("clear_button");
	}
}

applesearch.clearFld = function (fld,btn) {
	fld.value = "";
	this.onChange(fld,btn);
	fld.focus();
}

applesearch.insertPlaceholder = function(fld) {
  if(fld.value == "") {
	  fld.addClassName("placeholder");
	  fld.value = fld.getAttribute("placeholder");
  }
}

applesearch.removePlaceholder = function(fld) {
   if(fld.value == fld.getAttribute("placeholder")) {
	  fld.removeClassName("placeholder");
	  fld.value = "";
  }
}