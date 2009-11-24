// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.
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