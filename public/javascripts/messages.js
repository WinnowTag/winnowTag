// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
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

var ConfirmationMessage = Class.create();
ConfirmationMessage.prototype = {
  initialize: function(message, options) {
    this.options = {
      yes: "Yes",
      no: "No"
    }
		Object.extend(this.options, options || {});
		
    $('confirm').update(message + 
                        ' <a href="#" id="confirm_yes" onclick="return false;">' + this.options.yes + '</a>' +
                        ' or <a href="#" id="confirm_no" onclick="return false">' + this.options.no + '</a>');
    $('confirm_no').observe('click', function() { 
      $('confirm').hide();
      resizeContent(); 
      return false
    });
    $('confirm_yes').observe('click', function() { 
      $('confirm').hide(); 
      resizeContent();
      
      if (this.options.onConfirmed) {
        this.options.onConfirmed();        
      }
      
      return false;
    }.bindAsEventListener(this));    
    
    $('confirm').show();
    resizeContent();
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