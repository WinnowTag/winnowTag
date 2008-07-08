// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Item = Class.create({
  initialize: function(element) {
    this.element      = element;
    this.id           = this.element.getAttribute('id').match(/\d+/).first();
    this.closed       = this.element.down(".closed");
    this.status       = this.element.down(".status");
    this.add_tag      = this.element.down(".add_tag");
    this.add_tag_form = this.element.down(".add_tag_form");
    this.body         = this.element.down(".body");
    
    this.setupEventListeners();
    
    this.element._item = this;
  },
  
  setupEventListeners: function() {
    this.closed.observe("click", function(event) {
      itemBrowser.toggleOpenCloseItem(this.element, event);
    }.bind(this));

    this.status.observe("click", function() {
      this.toggleReadUnread();
    }.bind(this));

    this.status.observe("mouseover", function() {
      // # TODO: localization
      this.status.title = 'Click to mark as ' + (this.element.match(".read") ? 'unread' : 'read');
    }.bind(this));

    this.add_tag.observe("click", function() {
      itemBrowser.toggleOpenCloseModerationPanel(this.element);
    }.bind(this));
  },
  
  isRead: function() {
    return this.element.hasClassName("read");
  },
  
  markRead: function() {
    this.element.addClassName('read');
    new Ajax.Request('/feed_items/' + this.id + '/mark_read', { method: 'put' });
  },
  
  markUnread: function() {
    this.element.removeClassName('read');    
    new Ajax.Request('/feed_items/' + this.id + '/mark_unread', { method: 'put' });
  },
  
  toggleReadUnread: function() {
   this.isRead() ? this.markUnread() : this.markRead();
  },
  
  isSelected: function() {
    return this.element.hasClassName("selected");
  },
  
  scrollTo: function() {
    new Effect.ScrollToInDiv(this.element.up(), this.element, { duration: 0.3 });
  },
  
  loadBody: function() {
    this.load(this.body);
  },
  
  loadAddTagForm: function() {
    this.load(this.add_tag_form);
  },
  
  load: function(target) {
    if(!target.empty()) { return; }
    
    target.addClassName("loading");
    new Ajax.Request(target.getAttribute('url'), { method: 'get',
      onComplete: function() {
        target.removeClassName("loading");
        if(this.isSelected()) {
          this.scrollTo();
        }
      }.bind(this)
    });
  }
});