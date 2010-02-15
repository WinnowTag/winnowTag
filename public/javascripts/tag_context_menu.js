// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivative works.
// Please visit http://www.peerworks.org/contact for further information.

var activeMenu = null;

var TagContextMenu = Class.create({
  initialize: function(button, tag_id) {
    if (activeMenu) {
      activeMenu.destroy();
    }
    
    activeMenu = this;
    this.button = button;
    this.menu = $("tag_context_menu");
    
    this.tag_id = tag_id;
    this.tag_li = $("tag_" + tag_id);
    this.tag_li.addClassName("menu-up");
    
    this.positionMenu();
    this.registerHandlers();
    this.menu.show();
  },
  
  positionMenu: function() {
    var topPosition = this.button.cumulativeOffset()[1] + this.button.getHeight() + 2;
    var contextHeight = this.menu.getHeight();
    var viewportHeight = document.viewport.getHeight();
    
    if (topPosition + contextHeight > viewportHeight - 40) {
       this.menu.style.top = (topPosition - contextHeight - this.button.getHeight()) + "px";
    } else {
      this.menu.style.top = topPosition + "px";
    }
  },
  
  registerHandlers: function() {
    this.destroyHandler = this.destroy.bind(this);
    
    Event.observe(document, "click", this.destroyHandler);
  },
  
  destroy: function() {
    this.menu.hide();
    this.tag_li.removeClassName("menu-up");
    Event.stopObserving(document, "click", this.destroyHandler);
    if (this == activeMenu) {
      activeMenu = null;
    }
  }
});
