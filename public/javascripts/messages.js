// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

// Manages showing/hiding messages. Uses a queue to show messages in order.
// Will hide messages automatically after a timeout, unlesss autohide is
// explicitly disabled for a message.
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

// A TimeoutMessage is displayed when the server is slow to respond to the user's request.
var TimeoutMessage = Class.create({
  initialize: function(ajax) {
    this.timeout_id = TimeoutMessage.identifier++;
    this.ajax = ajax;

    var message = I18n.t("winnow.notifications.server_slow_responding", {
      cancel_link_start: '<a href="#" id="timeout_' + this.timeout_id + '">',
      cancel_link_end: '</a>'
    });
    Message.add("warning", message, false, function() {
      $("timeout_" + this.timeout_id).observe('click', this.cancel.bind(this));
    }.bind(this));
  },
  
  clear: function() {
    Message.hide();
  },
  
  cancel: function() {
    this.clear();

    if (this.ajax) {      
			// disable the standard Prototype state change handle to avoid
			// confusion between timeouts and exceptions
      this.ajax.transport.onreadystatechange = Prototype.emptyFunction;
      this.ajax.transport.abort();
      
      if (this.ajax.options.onComplete && !(this.ajax instanceof Ajax.Updater)) {
				this.ajax.options.onComplete(this.ajax.transport, this.ajax.json);
			}
    }
  }
});
TimeoutMessage.identifier = 1;