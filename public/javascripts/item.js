// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Item = Class.create({
  initialize: function(element) {
    this.element = element;
    this.status = this.element.down(".status");
    
    this.setupEventListeners();
    
    this.element._item = this;
  },
  
  setupEventListeners: function() {
    this.status.observe("click", function() {
      itemBrowser.toggleReadUnreadItem(this.element);
    }.bind(this));

    this.status.observe("mouseover", function() {
      // # TODO: localization
      this.status.title = 'Click to mark as ' + (this.element.match(".read") ? 'unread' : 'read');
    }.bind(this));
  }
});