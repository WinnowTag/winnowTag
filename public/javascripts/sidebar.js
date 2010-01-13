// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

// Manages the size and visible state of the sidebard on the items page.
var Sidebar = Class.create({
  initialize: function(url, parameters, onLoad) {
    this.sidebar = $('sidebar');
    this.sidebar.addClassName("loading");

    new Ajax.Updater(this.sidebar, url, { method: 'get', evalScripts: true, parameters: parameters,
      onComplete: function() {
        this.sidebar.removeClassName("loading");
        onComplete();
        document.fire('sidebar:loaded');
      }.bind(this)
    });
  }
});