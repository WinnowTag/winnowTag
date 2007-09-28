// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function enable_control(control) {
	$(control).removeClassName("disabled");
}

function disable_control(control) {
	$(control).addClassName("disabled");
}

var errorTimeout = null;
var ErrorMessage = Class.create();
ErrorMessage.prototype = {
	initialize: function(message) {
		if (errorTimeout) {
			clearTimeout(errorTimeout);
		}
		this.error_message = $('error_message');
		this.error_message.update(message);
		this.error_message.show();
		new Effect.Fade(this.error_message, {duration: 4});
		//errorTimeout = setTimeout(function(){new Effect.Fade(this.error_message);}.bind(this), 3000);
	}	
};

/** Ajax Responders to Handle time outs of Ajax requests */
Ajax.Responders.register({
	onCreate: function(request) {
		request.timeoutId = window.setTimeout(function() {
			var state = Ajax.Request.Events[request.transport.readyState];
			
			if (!['Uninitialized', 'Complete'].include(state)) {
				// disable the standard Prototype state change handle to avoid
				// confusion between timeouts and exceptions
				request.transport.onreadystatechange = Prototype.emptyFunction;
				request.transport.abort();
				
				if (request.options.onTimeout) {
					request.options.onTimeout(request.transport, request.json);
				} else {
					new ErrorMessage("Ajax request timed out. This should be handled by adding a onTimeout function to the request.");
				}
				
				if (request.options.onComplete && !(request instanceof Ajax.Updater)) {
					request.options.onComplete(request.transport, request.json);
				}
			}
		}, 10000);
	},
	onComplete: function(request) {
		if (request.timeoutId) {
			clearTimeout(request.timeoutId)
		}
	}
});

function selected_value_of(control_id) {
	var control = $(control_id);
	return control.options[control.selectedIndex].value;
}
function selected_display_of(control_id) {
	var control = $(control_id);
	return control.options[control.selectedIndex].innerHTML;
}

function resizeContent() {
	var content = $('content');
	if(content && !$('feed_items')) {
		var body_height = $(document.body).getDimensions().height;
		var page_title_height = $('page_title').getDimensions().height;
		var nav_bar_height = $('nav_bar').getDimensions().height;
		var flash_height = $('flash').getDimensions().height;
		var text_filter_height = $('header_controls').getHeight();
		var feed_item_height = body_height - nav_bar_height - page_title_height - flash_height - text_filter_height - 5;
		content.style.height = feed_item_height + 'px';		
	}
}


var lastFontSize;
function observeFontSizeChange(callback) {
	if( window.getComputedStyle ) {
		setInterval(function () {
			var currentFontSize = window.getComputedStyle(document.documentElement,null).fontSize;
			if( !lastFontSize || currentFontSize != lastFontSize ) {
				callback();
				lastFontSize = currentFontSize;
			}
		}, 500);
	} else {
		// do the IE hackaround	
	}
}
