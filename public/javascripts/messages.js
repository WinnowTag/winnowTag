// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Message = {
  queue: [],
  running: false,
  element: null,

  add: function(type, message, autohide, onShow) {
    this.queue.push({type: type, message: message, autohide: autohide, onShow: onShow});
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
      this.show(message.type, message.message, message.autohide, message.onShow);
    } else {
      this.stop();
    }
  },

  show: function(type, message, autohide, onShow) {
    this.element.addClassName(type);
    this.element.down(".content").update(message);
    if(onShow) { onShow(); }
    Effect.Appear(this.element, { to: this.element.getOpacity(),
      afterFinish: function() {
        // Content.instance.resize();
        if(autohide === undefined || autohide === true) {
          this.timeout = setTimeout(this.hide.bind(this), 10000);
        }
      }.bind(this)
    });
  },
  
  hide: function(type) {
    if(this.timeout) { clearTimeout(this.timeout); }
    
    Effect.Fade(this.element, {
      afterFinish: function() {
        // Content.instance.resize();
        this.element.removeClassName(this.element.classNames().toArray().last());
        this.showNext();
      }.bind(this)
    });
  }
}

var ConfirmationMessage = Class.create({
  initialize: function(message, onConfirmed) {    
    if(confirm(message)) {
      onConfirmed();
    }
  }
});

var TimeoutMessage = Class.create({
  initialize: function(ajax) {
    this.timeout_id = TimeoutMessage.identifier++;
    this.ajax = ajax;

    Message.add("warning", "The server is taking a while to repond. We'll keep trying but you can " +
                           '<a href="#" id="timeout_' + this.timeout_id + '">cancel</a> if you like.', false, function() {
      $("timeout_" + this.timeout_id).observe('click', this.cancel.bind(this));
    }.bind(this));
  },
  
  clear: function() {
    Message.hide();
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