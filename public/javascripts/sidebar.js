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
    
    if (Cookie.get("training_mode") == "on") {
      this.togglePanel();
    }
    
    $("sidebar_edit_toggle").observe("click", this.toggleEdit.bind(this));
  },
  
  toggleEdit: function() {
    this.clearFields();
    this.togglePanel(function() {
      this.toggleOpenItemTraining();
      this.toggleCookies();
    }.bind(this));
  },
  
  togglePanel: function(afterFinish) {
    Effect.toggle("sidebar_edit", "slide", {
      afterUpdate: function(effect) {
        var height = $(effect.element).getHeight();
        this.sidebar_normal.style.top = (25 + height) + "px";
      }.bind(this),
      afterFinish: function(e) {
        this.toggleControl();
        
        if (!this.isEditing()) {
          this.sidebar_normal.style.top = "25px";
        }
        
        if (afterFinish) {
          afterFinish();
        }
      }.bind(this),
      duration: 0.3,
      queue: {
        position: 'end',
        scope: 'sidebarToggle',
        limit: 1
      }
    });
  },
  
  toggleCookies: function() {
    Cookie.set("training_mode", this.isEditing() ? "on" : "off");
  },
  
  toggleControl: function() {
    $$("#sidebar_edit_toggle").each(function(e) {
      if (this.isEditing()) {
        e.addClassName("open");
        e.removeClassName("closed");
      } else {
        e.addClassName("closed");
        e.removeClassName("open");
      }
    }.bind(this));
  },
  
  clearFields: function() {
    var clearedFilters = {};
    var needToClear = false;
    
    if (itemBrowser.filters.mode != "all") {
      clearedFilters.mode = "all";
      needToClear = true;
    }
    
    if (itemBrowser.filters.text_filter) {
      clearedFilters.text_filter = "";
      needToClear = true;
    }
    
    if (needToClear) {
      itemBrowser.addFilters({mode: "all", text_filter: ""});      
    }
    
    $("text_filter").clear();
    $("text_filter").showPlaceholder();
  },
  
  isEditing: function() {
    return $("sidebar_edit").visible();
  },
  
  toggleOpenItemTraining: function() {
    var selectedItem = itemBrowser.selectedItem();
    if (selectedItem && selectedItem._item.isOpen()) {
      if (this.isEditing()) {
        selectedItem._item.showTrainingControls();
      } else {
        selectedItem._item.hideTrainingControls();
      }
    }
  }
});
