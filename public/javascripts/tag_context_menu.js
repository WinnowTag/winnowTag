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
    this.tag_id = this.button.getAttribute("tag-id");
    this.path = "/tags/" + this.tag_id;
    
    if (this.isSubscribedPublicTag()) {
      this.menu.addClassName("public");
    }
    
    this.tag_li = $("tag_" + tag_id);
    this.tag_li.addClassName("menu-up");
    
    this.positionMenu();
    this.registerHandlers();
    this.menu.show();
  },
  
  isSubscribedPublicTag: function() {
    return $$("li#tag_" + this.tag_id + ".tag.public").length != 0;
  },
  
  getName: function() {
    return $("name_tag_" + this.tag_id).innerHTML;
  },
  
  positionMenu: function() {
    var topPosition = this.button.cumulativeOffset()[1] - this.button.cumulativeScrollOffset()[1] + this.button.getHeight() + 2;
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
    
    this.clickHandler = this.click.bindAsEventListener(this);
    
    this.menu.select("li").each(function(item) {
      Event.observe(item, "click", this.clickHandler);
    }.bind(this));
    
    Event.observe(document, "click", this.destroyHandler);
  },
  
  click: function(event) {
    var element = event.findElement("li");
    var id = element.getAttribute("id");
    var action = "";
    
    if ((match = /(.*)_menu_item/.exec(id)) != null) {
      action = match[1];
    }
    
    if (this[action]) {
      this[action]();
    } else {
      alert(action + " not implemented!!");
    }
  },
  
  rename: function() {
    if (!this.isSubscribedPublicTag()) {
      var newName = prompt("Please enter a new name for the tag:", this.getName());
      if (newName && newName != this.getName()) {
        new Ajax.Request(this.path, {
              parameters: { 'tag[name]': newName },
              method: 'put',
              requestHeaders: { Accept: 'application/json' },
              onSuccess: function(response) {
                var data = response.responseJSON;
                $$(".tag_" + this.tag_id).each(function(e) {
                  e.down('.name').update(data.name);
                  e.up().insertInOrder('.name', e, data.name);
                  new Effect.ScrollToInDiv($("tag_container"), e, 12);
                  new Effect.Highlight(e, {queue: 'end', endcolor: "#FEF3BB"});
                });
              }.bind(this)
            });
      }
    }
  },
  
  delete: function() {
    
  },
  
  destroy: function() {
    this.menu.hide();
    this.tag_li.removeClassName("menu-up");
    this.menu.removeClassName("public");
    
    Event.stopObserving(document, "click", this.destroyHandler);
    
    this.menu.select("li").each(function(item) {
      Event.stopObserving(item, "click", this.clickHandler);
    }.bind(this));
    
    if (this == activeMenu) {
      activeMenu = null;
    }
  }
});
