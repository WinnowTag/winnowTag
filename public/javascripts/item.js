// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Item = Class.create({
  initialize: function(element) {
    this.element          = element;
    this.id               = this.element.getAttribute('id').match(/\d+/).first();
    this.closed           = this.element.down(".closed");
    this.status           = this.element.down(".status");
    this.add_tag          = this.element.down(".add_tag");
    this.moderation_panel = this.element.down(".moderation_panel");
    this.feed_information = this.element.down(".feed_information");
    this.body             = this.element.down(".body");
    this.add_tag_field    = this.moderation_panel.down("input[type=text]");
    
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
      this.toggleAddTagForm();
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
  
  loadFeedInformation: function() {
    this.load(this.feed_information);
  },
  
  toggleAddTagForm: function() {
    if(this.moderation_panel.hasClassName("selected")) {
      this.hideAddTagForm();
    } else {
      this.showAddTagForm();
    }
  },
  
  showAddTagForm: function() {
    if(!this.isSelected()) {
      itemBrowser.closeItem(itemBrowser.selectedItem);
      itemBrowser.selectItem(this.element);
    }

    this.moderation_panel.addClassName("selected");
    this.add_tag.addClassName("selected");
    this.loadAddTagForm();
    this.scrollTo();

    itemBrowser.initializeItemModerationPanel(this.element, false);
  },
  
  hideAddTagForm: function() {
    this.moderation_panel.removeClassName("selected");
    this.add_tag.removeClassName("selected");
    this.add_tag_field.blur();
  },

  loadAddTagForm: function() {
    this.load(this.moderation_panel, function() {
      this.add_tag_field = this.moderation_panel.down("input[type=text]");
      itemBrowser.initializeItemModerationPanel(this.element, true);
    }.bind(this));
  },
  
  load: function(target, onComplete) {
    if(!target.empty()) { return; }
    
    target.addClassName("loading");
    new Ajax.Updater(target, target.getAttribute("url"), { method: 'get',
      onComplete: function() {
        target.removeClassName("loading");
        if(onComplete)        { onComplete();    }
        if(this.isSelected()) { this.scrollTo(); }
      }.bind(this)
    });
  }
});