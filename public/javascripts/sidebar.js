// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

// Manages the size and visible state of the sidebard on the items page.
var Sidebar = Class.create({
  initialize: function() {
    this.sidebar = $('sidebar');
    this.sidebar_normal = $('sidebar_normal');
  },
  
  toggleEdit: function() {
    this.toggleControl();
    Effect.toggle("sidebar_edit", "blind", {
      afterUpdate: function(effect) {
        var height = $(effect.element).getHeight();
        var sidebarHeight = this.sidebar.getHeight();
        this.sidebar_normal.style.height = "" + (sidebarHeight - height) + "px";
      }.bind(this),
      duration: 0.3
    });
  },
  
  toggleControl: function() {
    $$("#sidebarEditToggle span.icon").each(function(e) {
      if (e.hasClassName("edit")) {
        e.update("Done");
        e.removeClassName("edit");
        e.addClassName("done");
      } else {
        e.update("Edit");
        e.removeClassName("done");
        e.addClassName("edit");
      }
    });
  }
});