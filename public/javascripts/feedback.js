// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Feedback = Class.create({
  initialize: function(element) {
    this.element = element;
    this.link = this.element.down("a");
    this.link.observe("click", function(event) {
      this.show();
      event.stop();
    }.bind(this));
  },
  
  show: function() {
    if(this.form) {
      this.form.show();
    } else {
      this.load();
    }
  },
  
  load: function() {
    new Ajax.Request(this.link.href, { method: 'get',
      onSuccess: function(response) {
        this.form = Element.fromHTML(response.responseText);
        this.form.observe("submit", function(event) {
          this.submit();
          event.stop();
        }.bind(this));
        this.form.down(".cancel").observe("click", this.hide.bind(this));
        this.element.insert(this.form);
      }.bind(this)
    });
  },
  
  hide: function() {
    this.form.hide();
    this.form.reset();
  },

  submit: function() {
    new Ajax.Request(this.form.action, {
      method: this.form.method, parameters: this.form.serialize(),
      onSuccess: this.hide.bind(this)
    });
  }
});

document.observe('dom:loaded', function() {
  $$("#feedback").each(function(feedback) {
    new Feedback(feedback);
  });
});