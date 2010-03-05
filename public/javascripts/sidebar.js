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
    this.clearFields();
    Effect.toggle("sidebar_edit", "blind", {
      afterUpdate: function(effect) {
        var height = $(effect.element).getHeight();
        var sidebarHeight = this.sidebar.getHeight();
        this.sidebar_normal.style.height = "" + (sidebarHeight - height) + "px";
      }.bind(this),
      afterFinish: function(e) {
        if (!this.isEditing()) {
          this.sidebar_normal.style.height = "100%";
        }
        this.toggleOpenItemTraining();
      }.bind(this),
      duration: 0.3
    });
  },
  
  toggleControl: function() {
    $$("#sidebarEditToggle").each(function(e) {
      if (e.hasClassName("done")) {
        e.update("Train");
        e.removeClassName("done");
      } else {
        e.update("Done");
        e.addClassName("done");
      }
    });
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
