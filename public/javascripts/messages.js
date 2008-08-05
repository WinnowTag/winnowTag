// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Message = {
  queue: [],
  running: false,
  element: null,

  add: function(type, message) {
    this.queue.push({type: type, message: message});
    this.start();
  },
  
  start: function() {
    if(this.running) { return; }
    this.running = true;
    this.element = $("messages");
    this.element.down(".close").observe("click", this.hide.bind(this));
    this.showNext();
  },
  
  stop: function() {
    this.running = false;
  },
  
  showNext: function() {
    var message = this.queue.shift();
    
    if(message) {
      this.show(message.type, message.message);
    } else {
      this.stop();
    }
  },

  show: function(type, message) {
    this.element.addClassName(type);
    this.element.down(".content").update(message);
    Effect.Appear(this.element, { to: this.element.getOpacity(),
      afterFinish: function() {
        this.timeout = setTimeout(this.hide.bind(this), 10000);
      }.bind(this)
    });
  },
  
  hide: function(type) {
    if(this.timeout) { clearTimeout(this.timeout); }
    
    Effect.Fade(this.element, {
      afterFinish: function() {
        this.element.removeClassName(this.element.classNames().toArray().last());
        this.showNext();
      }.bind(this)
    });
  }
}

var ConfirmationMessage = Class.create({
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
      Effect.Fade('confirm');
      return false;
    });
    $('confirm_yes').observe('click', function() { 
      Effect.Fade('confirm');

      if (this.options.onConfirmed) {
        this.options.onConfirmed();        
      }
      
      return false;
    }.bindAsEventListener(this));    
    
    Effect.Appear('confirm');
  }
});

var TimeoutMessage = Class.create({
  initialize: function(ajax) {
    this.timeout_id = TimeoutMessage.identifier++;
    this.error_message = $('error');
    this.ajax = ajax;
    
    if (this.error_message) {
      this.error_message.update("The server is taking a while to repond. " + 
                                "We'll keep trying but you can " +
                                "<a href=\"#\" id=\"timeout" + this.timeout_id + "\">cancel</a>" +
                                " if you like.");
      Event.observe("timeout" + this.timeout_id, 'click', this.cancel.bindAsEventListener(this));
      Effect.Appear(this.error_message);
    }
  },
  
  clear: function() {
    Effect.Fade(this.error_message);
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
});
TimeoutMessage.identifier = 1;